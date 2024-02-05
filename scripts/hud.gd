extends Control

@onready var timer: Label = $Timer
@onready var scoped: Control = $Scoped
@onready var fps: Label = $FPS
@onready var crosshair: Control = $CenterContainer
@onready var ammo: Label = $Ammo
@onready var ammo_bar: ProgressBar = $AmmoBar

@onready var dashes: Label = $Dashes
@onready var dash_bar: ProgressBar = $DashBar

@onready var second_hand: Control = $SecondHand
@onready var minute_hand: Control = $MinuteHand
@onready var hour_hand: Control = $HourHand

@onready var flash: ColorRect = $Flash
@onready var twinkle: AnimatedSprite2D = $Flash/CenterContainer/Control/Twinkle
@onready var sfx_death: AudioStreamPlayer = $Death
@onready var music: AudioStreamPlayer = $Music

@onready var boss_health_bar: ProgressBar = $BossHealthBar
@onready var boss_health_label: Label = $BossHealthBar/Label

@onready var sfx_boss_death: AudioStreamPlayer = $BossDeath

@onready var screenshader: CanvasLayer = $ScreenShader

@onready var white: ColorRect = $White
@onready var credits: Label = $Credits

@onready var minus_three: PackedScene = preload("res://scenes/minus_three.tscn")
@onready var minus_one: PackedScene = preload("res://scenes/minus_one.tscn")
@onready var plus_one: PackedScene = preload("res://scenes/plus_one.tscn")

@onready var music_boss: AudioStreamMP3 = preload("res://sound/music_boss.mp3")
@onready var music_hub: AudioStreamMP3 = preload("res://sound/music_hub.mp3")
@onready var music_tutorial: AudioStreamMP3 = preload("res://sound/music_tutorial.mp3")

enum ParticleType {
	TIMES_TWO,
	TIMES_HALF,
	MINUS_THREE
}

@onready var bolt_ammo: TextureProgressBar = $BoltAmmo
@onready var bolt_dmg: Label = $BoltAmmo/amt
@onready var vignette: ShaderMaterial = $Vignette.material

@export var styles: Array[StyleBox]

var time: float
var start_ms: int
var pervious_ms: int
var spawn_one_time: int

var flash_T: float = 0.0
var timer_pos: Vector2

var rng := RandomNumberGenerator.new()
const SHAKE_STRENGTH: float = 5.0

var boss_hb_init_pos: Vector2
static var boss_health_bar_shake: float = 0.0



var pause_timer: bool = false

class MinusOneParticle extends RefCounted:
	var visual: Control
	var velocity: Vector2

var minus_one_particles: Array[MinusOneParticle] = []

var fade_to_white_T: float = 0.0

func update_boss_health(hp: int) -> void:
	boss_health_bar.value = hp
	boss_health_label.text = "%d" % ceil(hp / boss_health_bar.max_value * 100)

func shake_health() -> void:
	boss_health_bar_shake = 1.0

func set_visiblity() -> void:
	timer.visible = false
	second_hand.visible = false
	hour_hand.visible = false
	minute_hand.visible = false
	boss_health_bar.visible = false
	$Shadow.visible = false
	bolt_ammo.visible = false
	dashes.visible = false
	dash_bar.visible = false
	ammo_bar.visible = false
	ammo.visible = false
	match SceneManager.scene:
		SceneManager.Scene.LOBBY:
			bolt_ammo.visible  = true
			dashes.visible= true
			dash_bar.visible = true
			ammo_bar.visible = true
			ammo.visible = true
		SceneManager.Scene.DIFFICULTY:
			bolt_ammo.visible  = true
			dashes.visible= true
			dash_bar.visible = true
			ammo_bar.visible = true
			ammo.visible = true
		SceneManager.Scene.TUTORIAL_1:
			ammo.visible = true
			ammo_bar.visible = true
		SceneManager.Scene.TUTORIAL_2:
			ammo.visible = true
			ammo_bar.visible = true
		SceneManager.Scene.TUTORIAL_3:
			bolt_ammo.visible  = true
		SceneManager.Scene.TUTORIAL_4:
			bolt_ammo.visible  = true
		SceneManager.Scene.TUTORIAL_5:
			dashes.visible= true
			dash_bar.visible = true
		SceneManager.Scene.TUTORIAL_6:
			timer.visible = true
			second_hand.visible = true
			hour_hand.visible = true
			minute_hand.visible = true
			$Shadow.visible = true
		_:
			timer.visible = true
			boss_health_bar.visible = true
			second_hand.visible = true
			hour_hand.visible = true
			minute_hand.visible = true
			$Shadow.visible = true
			bolt_ammo.visible = true
			dashes.visible= true
			dash_bar.visible = true
			ammo_bar.visible = true
			ammo.visible = true
			

func reset() -> void:
	set_visiblity()
	credits.modulate.a = 0
	white.color = Color.TRANSPARENT
	pause_timer = false
	fade_to_white_T = 0.0
	time = 100.00
	flash_T = 0
	spawn_one_time = 99
	
	music.stop()
	if SceneManager.scene == SceneManager.Scene.BOSS_1 \
	or SceneManager.scene == SceneManager.Scene.BOSS_2:
		music.stream = music_boss
	elif SceneManager.scene == SceneManager.Scene.TUTORIAL_1 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_2\
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_3\
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_4\
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_5\
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_6:
		music.stream = music_tutorial
	elif SceneManager.scene == SceneManager.Scene.LOBBY \
	or SceneManager.scene == SceneManager.Scene.DIFFICULTY:
		music.stream = music_hub
	
	music.play(0.0)
		
	sfx_death.stop()
	vignette.set_shader_parameter("SCALE", 0.0)
	for p: MinusOneParticle in minus_one_particles:
		p.visual.queue_free()
		p.unreference()
	minus_one_particles.clear()

func _ready() -> void:
	start_ms = Time.get_ticks_msec()
	pervious_ms = start_ms
	PitchChanger.register_player(music)
	timer_pos = timer.position
	boss_hb_init_pos = boss_health_label.position
	Character.connect("parry", _on_parry)
	Controls.connect("death", _on_death)
	vignette.set_shader_parameter("SCALE", 0)
	reset()
	
func _on_parry() -> void:
	flash_T = 1
	#twinkle.stop()
	#twinkle.play("default", 1, false)

func _on_death() -> void:
	sfx_death.play()
	flash_T = 0
	flash.color.a = 1
	twinkle.frame = 60

func spawn_one_particle(type: ParticleType) -> void:
	if SceneManager.scene == SceneManager.Scene.BOSS_1 \
	or SceneManager.scene == SceneManager.Scene.BOSS_2 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_6:
		var which: PackedScene
		match type:
			ParticleType.TIMES_TWO:
				which = minus_one
			ParticleType.TIMES_HALF:
				which = plus_one
			ParticleType.MINUS_THREE:
				which = minus_three
		var v: Control = which.instantiate() as Control
		add_child(v)
		v.position = timer.position + timer.pivot_offset
		var part: MinusOneParticle = MinusOneParticle.new()
		part.visual = v
		part.velocity = Vector2((randf() * 2 - 1) * 200, -500.0)
		minus_one_particles.push_back(part)
	
func animate_particles(delta: float) -> void:
	delta /= 1000.00
	for i: int in range(minus_one_particles.size() - 1, -1, -1):
		var part: MinusOneParticle = minus_one_particles[i]
		part.visual.global_position += part.velocity * delta
		part.velocity += Vector2(0.0, 400.0 * delta)
		if part.visual.global_position.y >= 1080:
			part.visual.queue_free()
			part.unreference()
			minus_one_particles.remove_at(i)

func bell_cruve(x: float) -> float:
	return cos((x * PI * 2.0) - PI) + 1.0 if x < 1.0 else 0.0

func ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0);

func _process(_dt: float) -> void:
	if Menu.enabled:
		pervious_ms = Time.get_ticks_msec()
		return
		
	if Controls.is_dead:
		scoped.visible = false
		flash.color.a = remap(bell_cruve(Controls.dead_timer * 4.0), 0, 1, 0, 0.25)
		var time_remap: float = remap(Controls.dead_timer, 0, 4.6, 0, 1)
		var val: float = remap(ease_out_cubic(time_remap), 0, 1, 3, 0)
		val = clampf(val, 0, 5)
		vignette.set_shader_parameter("SCALE", val)
		pervious_ms = Time.get_ticks_msec()
		return
		
	var current_ms: int = Time.get_ticks_msec()
	var ms_diff: float = current_ms - pervious_ms
	pervious_ms = current_ms
	
	if not pause_timer:
		time -= (ms_diff / 1000.00 * Controls.clock_speed)
		timer.text = "%.1f" % time
	else:
		fade_to_white_T += ms_diff / 4000.00
		
		Camera.trauma = remap(fade_to_white_T, 0.0, 0.25, 0.0, 0.5)
		Camera.trauma = min(0.5, Camera.trauma)
		white.color = Color(1, 1, 1, fade_to_white_T)
		var db: float = linear_to_db(1 - fade_to_white_T)
		var bus_idx: int = AudioServer.get_bus_index("Effects")
		AudioServer.set_bus_volume_db(bus_idx, db)
		
		var credits_alpha: float = remap(fade_to_white_T, 1.0, 1.25, 0.0, 1.0)
		credits_alpha = clampf(credits_alpha, 0.0, 1.0)
		credits.modulate.a = credits_alpha
		
		if fade_to_white_T >= 2.0:
			SceneManager.goto_lobby()
	
	if time < 0:
		time = 0
		if SceneManager.scene == SceneManager.Scene.BOSS_1 \
		or SceneManager.scene == SceneManager.Scene.BOSS_2 \
		or SceneManager.scene == SceneManager.Scene.TUTORIAL_6:
			Controls.invoke_player_death()
	
	if time <= spawn_one_time and time > 0:
		if Controls.clock_speed < 1.025 and Controls.clock_speed > 0.975:
			pass
		elif Controls.clock_speed > 1.025:
			spawn_one_particle(ParticleType.TIMES_TWO)
		elif Controls.clock_speed < 0.975:
			spawn_one_particle(ParticleType.TIMES_HALF)
		# Truncate float to integer, effectively minus 1
		spawn_one_time = time as int
	
	animate_particles(ms_diff)
	
	boss_health_bar_shake -= ms_diff / 500.0
	boss_health_bar_shake = clampf(boss_health_bar_shake, 0, 1.0)
	#print(boss_health_bar_shake)
	var hb_strength: float = remap(boss_health_bar_shake, 0.0, 1.0, 0, SHAKE_STRENGTH)
	var hb_shake_vec := Vector2(rng.randf_range(-hb_strength, hb_strength), rng.randf_range(-hb_strength, hb_strength))
	boss_health_label.position = boss_hb_init_pos + hb_shake_vec
	
	bolt_ammo.value = BulletServer.bolt_damage
	if SceneManager.scene == SceneManager.Scene.BOSS_1 \
		or SceneManager.scene == SceneManager.Scene.BOSS_2 \
		or SceneManager.scene == SceneManager.Scene.LOBBY \
		or SceneManager.scene == SceneManager.Scene.DIFFICULTY \
		or SceneManager.scene == SceneManager.Scene.TUTORIAL_3 \
		or SceneManager.scene == SceneManager.Scene.TUTORIAL_4:
		bolt_ammo.visible = BulletServer.bolt_state == BulletServer.BoltState.COLLECTED
	
	
	
	bolt_dmg.text = str(BulletServer.bolt_damage as int)
	
	flash_T -= ms_diff / 500.0
	flash.color.a = remap(flash_T, 0.0, 1.0, 0.0, 0.5)
	twinkle.modulate = Color(1,1,1,remap(flash_T, 0.0, 1.0, 0.0, 0.5))
	twinkle.frame = remap(flash_T, 1.0, 0.0, 0.0, 60.0) as int
	var s: float = remap(flash_T, 0.0, 1.0, 0.0, 2.0)
	twinkle.scale = Vector2(s,s)
	twinkle.rotation = remap(flash_T, 0.0, 1.0, -45.0, 0.0)
	
	var strength: float = remap(clampf(Controls.clock_speed, 1.0, 2.0), 1.0, 2.0, 0, SHAKE_STRENGTH)
	var shake_vec := Vector2(rng.randf_range(-strength, strength), rng.randf_range(-strength, strength))
	timer.position = timer_pos + shake_vec
	
	ammo.text = str(BulletServer.valid_bullets)
	ammo_bar.value = BulletServer.valid_bullets
	dash_bar.value = Controls.dash_meter
	var dashes_int: int = floorf(Controls.dash_meter) as int
	dashes.text = str(dashes_int)
	#if dashes_int == 0:
	dash_bar.add_theme_stylebox_override("fill", styles[dashes_int])

	var vig: float = remap(time, 100.0, 99.7, 0.0, 3.0)
	vig = clampf(vig, 0.0, 3.0)
	vignette.set_shader_parameter("SCALE", vig)

	second_hand.rotation = time * -7
	minute_hand.rotation = time * 5
	hour_hand.rotation = time * -2

	scoped.visible = Controls.get_sniper_scope()
	crosshair.visible = not scoped.visible
	
	fps.text = "FPS: %d" % Engine.get_frames_per_second()

#func set_scope(vis: bool) -> void:
	#scoped.visible = vis

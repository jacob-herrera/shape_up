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
@onready var music: AudioStreamPlayer = $TempMusic

@onready var minus_one: PackedScene = preload("res://scenes/minus_one.tscn")
@onready var plus_one: PackedScene = preload("res://scenes/plus_one.tscn")

@onready var bolt_ammo: Control = $BoltAmmo

@onready var vignette: ShaderMaterial = $Vignette.material

@export var styles: Array[StyleBox]

var time: float = 100.000
var start_ms: int
var pervious_ms: int

var flash_T: float = 0.0
var timer_pos: Vector2

var rng := RandomNumberGenerator.new()
const SHAKE_STRENGTH: float = 5.0

var spawn_one_time: int = 99

class MinusOneParticle extends RefCounted:
	var visual: Control
	var velocity: Vector2

var minus_one_particles: Array[MinusOneParticle] = []

func reset() -> void:
	time = 100.00
	spawn_one_time = 99
	music.stop()
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
	timer_pos = timer.global_position
	Controls.connect("parry", _on_parry)
	Controls.connect("death", _on_death)
	vignette.set_shader_parameter("SCALE", 0)
	
func _on_parry() -> void:
	flash_T = 1
	#twinkle.stop()
	#twinkle.play("default", 1, false)

func _on_death() -> void:
	sfx_death.play()

func spawn_one_particle(green: bool) -> void:
	var which: PackedScene = plus_one if green else minus_one
	var v: Control = which.instantiate() as Control
	add_child(v)
	v.global_position = timer.global_position + timer.pivot_offset
	var part: MinusOneParticle = MinusOneParticle.new()
	part.visual = v
	part.velocity = Vector2((randf() * 2 - 1) * 200, -300.0)
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
	time -= (ms_diff / 1000.00 * Controls.clock_speed)
	timer.text = "%.1f" % time
	
	if time < 0:
		time = 0
	
	if time <= spawn_one_time and time > 0:
		if Controls.clock_speed < 1.025 and Controls.clock_speed > 0.975:
			pass
		elif Controls.clock_speed > 1.025:
			spawn_one_particle(false)
		elif Controls.clock_speed < 0.975:
			spawn_one_particle(true)
		# Truncate float to integer, effectively minus 1
		spawn_one_time = time as int
	
	animate_particles(ms_diff)
	
	bolt_ammo.visible = BulletServer.bolt_state == BulletServer.BoltState.COLLECTED
	
	flash_T -= ms_diff / 500.0
	flash.color.a = remap(flash_T, 0.0, 1.0, 0.0, 0.5)
	twinkle.frame = remap(flash_T, 1.0, 0.0, 0.0, 60.0) as int
	
	var strength: float = remap(clampf(Controls.clock_speed, 1.0, 2.0), 1.0, 2.0, 0, SHAKE_STRENGTH)
	var shake_vec := Vector2(rng.randf_range(-strength, strength), rng.randf_range(-strength, strength))
	timer.global_position = timer_pos + shake_vec
	
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

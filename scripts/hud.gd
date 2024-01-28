extends Control

@onready var timer: Label = $Timer
@onready var scoped: TextureRect = $Scoped
@onready var fps: Label = $FPS
@onready var crosshair: Control = $CenterContainer
@onready var ammo: Label = $Ammo
@onready var ammo_bar: ProgressBar = $AmmoBar

@onready var dashes: Label = $Dashes
@onready var dash_Bar: ProgressBar = $DashBar

@onready var second_hand: Control = $SecondHand
@onready var minute_hand: Control = $MinuteHand
@onready var hour_hand: Control = $HourHand

@onready var minus_one: PackedScene = preload("res://scenes/minus_one.tscn")
@onready var plus_one: PackedScene = preload("res://scenes/plus_one.tscn")

var time: float = 100.000
var start_ms: int
var pervious_ms: int

var timer_pos: Vector2

var rng := RandomNumberGenerator.new()
const SHAKE_STRENGTH: float = 5.0

var spawn_one_time: int = 99

class MinusOneParticle extends RefCounted:
	var visual: Control
	var velocity: Vector2

var minus_one_particles: Array[MinusOneParticle] = []

func _ready() -> void:
	start_ms = Time.get_ticks_msec()
	pervious_ms = start_ms
	PitchChanger.register_player($TempMusic)
	timer_pos = timer.global_position
	
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

func _process(dt: float) -> void:
	if Menu.enabled:
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
		# Truncate float to integer, effectively minus 1
		if Controls.clock_speed == 1:
			pass
		elif Controls.clock_speed > 1:
			spawn_one_particle(false)
		elif Controls.clock_speed < 1:
			spawn_one_particle(true)
			
		spawn_one_time = time
	
	animate_particles(ms_diff)
	
	var strength: float = remap(clampf(Controls.clock_speed, 1.0, 2.0), 1.0, 2.0, 0, SHAKE_STRENGTH)
	var shake_vec := Vector2(rng.randf_range(-strength, strength), rng.randf_range(-strength, strength))
	timer.global_position = timer_pos + shake_vec
	
	ammo.text = str(BulletServer.valid_bullets)
	ammo_bar.value = BulletServer.valid_bullets
	dash_Bar.value = Controls.dash_meter
	dashes.text = str(floorf(Controls.dash_meter))
	#music.pitch_scale = Controls.clock_speed
	#print(pitch.pitch_scale)
	second_hand.rotation = time * -7
	minute_hand.rotation = time * 5
	hour_hand.rotation = time * -2

	scoped.visible = Controls.get_sniper_scope()
	crosshair.visible = not scoped.visible
	
	fps.text = "FPS: %d" % Engine.get_frames_per_second()

#func set_scope(vis: bool) -> void:
	#scoped.visible = vis

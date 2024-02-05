extends Node3D

@onready var mat: ShaderMaterial = $Visual/Mesh.material_override
@onready var visual: Node3D = $Visual
@onready var laser_parry: Area3D = $LaserParry
@onready var laser_damage: Area3D = $LaserDamage



var RNG := RandomNumberGenerator.new()
const SHAKE_STRENGTH: float = 0.5

var line_3d: PackedScene = preload("res://scenes/boss_laser.tscn")
var line: LineRenderer

const FAR_AWAY: Vector3 = Vector3(0, -100, 0)


@export var laser_animate_curve: Curve
const LASER_MIN_RANDOM_TIME: float = 3.0
const LASER_MAX_RANDOM_TIME: float = 8.0
const LASER_LENGTH: float = 256.0

enum BossState{
	DEAD,
	CENTER,
	STOP
}

enum BossAttack { 
	LASER
}

var state: BossState
#var 

var max_health: float
var health: float

var time: float = 0.0 
var amt: float = 0.0
var FADE_RATE: float = 4.0

var delay: float = 2.0

var laser_fired: bool
const LASER_DELAY: float = 0.47
var laser_lifetime: float
var laser_delay: float

func _ready() -> void:
	laser_fired = true
	laser_delay = -LASER_DELAY
	laser_lifetime = 110.0
	max_health = 2000
	health = max_health
	state = BossState.CENTER
	HUD.boss_health_bar.max_value = max_health
	HUD.update_boss_health(max_health)
	line = line_3d.instantiate()
	add_child(line)
	line.set_camera(get_viewport().get_camera_3d())

func _exit_tree() -> void:
	line.queue_free()

func _on_death() -> void:
	state = BossState.DEAD
	Character.invincible = true
	HUD.pause_timer = true
	HUD.music.stop()
	PitchChanger.stop_all_sfx()
	HUD.sfx_boss_death.play()

func _dead_process() -> void:
	pass
	
func _alive_process(delta: float) -> void:
	if health <= 0: _on_death(); return
	
	var laser_alpha: float = remap(laser_lifetime, 0.0, 1.0, 1.0, 0.0)
	laser_alpha = clampf(laser_alpha, 0.0, 1.0)
	line.material.set_shader_parameter("alpha", laser_alpha)
	
	delay -= delta
	laser_delay -= delta
	laser_lifetime += delta
	
	var T: float = remap(laser_delay, LASER_DELAY, -LASER_DELAY, 0.0, 1.0)
	var amt: float = laser_animate_curve.sample(T) - 0.5
	print(amt)
	scale = Vector3(1 - amt, 1 + amt, 1 - amt)
	
	if not laser_fired and laser_delay <= 0.0:
		fire_laser()
	
	if delay <= 0:
		Character.sfx_boss_laser.play()
		laser_fired = false
		laser_delay = LASER_DELAY
		delay = randf_range(LASER_MIN_RANDOM_TIME, LASER_MAX_RANDOM_TIME)
		

		
func fire_laser() -> void:
	laser_fired = true
	var dir: Vector3 = global_position.direction_to(Character.global_position)
	line.points[0] = global_position
	line.points[1] = global_position + dir * LASER_LENGTH
	laser_lifetime = 0.0
	laser_damage.disabled = false
	laser_damage.skip_frames = 2
	laser_parry.global_position = global_position
	laser_parry.look_at(Character.global_position)
	laser_damage.global_position = global_position
	laser_damage.look_at(Character.global_position)

func _process(delta: float) -> void:
	if Menu.enabled or Controls.is_dead: return 
		
	amt -= delta * FADE_RATE
	mat.set_shader_parameter("amt", clampf(amt, 0.0, 1.0))
	
	var strength: float = remap(clampf(amt, 0.0, 1.0), 0.0, 1.0, 0, SHAKE_STRENGTH)
	var shake_vec := Vector3(RNG.randf_range(-strength, strength), RNG.randf_range(-strength, strength) , RNG.randf_range(-strength, strength))
	visual.global_position = global_position + shake_vec
	
	if state == BossState.DEAD:
		_dead_process()
	else:
		_alive_process(delta)
	
	
func laser_parried() -> void:
	laser_damage.disabled = true
	laser_parry.global_position = FAR_AWAY
	laser_damage.global_position = FAR_AWAY
	
func _on_hit(dmg: int) -> void:
	health -= dmg
	health = max(0, health)
	amt = 1.25
	HUD.shake_health()
	Character.sfx_hit.play()
	HUD.update_boss_health(health)

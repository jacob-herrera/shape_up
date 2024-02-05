extends Node3D

@onready var mat: ShaderMaterial = $Visual/Mesh.material_override
@onready var visual: Node3D = $Visual
@onready var laser_parry: Area3D = $LaserParry
@onready var laser_damage: Area3D = $LaserDamage
@onready var spikes: MeshInstance3D = $Spikes

@onready var spinner: Node3D = $spinner
@onready var spinner_killer: Hurtbox = $spinner/kill

var RNG := RandomNumberGenerator.new()
const SHAKE_STRENGTH: float = 0.5

var line_3d: PackedScene = preload("res://scenes/boss_laser.tscn")
var line: LineRenderer

const FAR_AWAY: Vector3 = Vector3(0, -100, 0)

const SPIKES_MIN_HEIGHT: float = -5.0
const SPIKES_MAX_HEIGHT: float = -2.0

@export var laser_animate_curve: Curve
@export var spike_curve: Curve

@export var center_indicator_alpha: Curve
@export var center_pillar_alpha: Curve
@export var center_spin_rate: Curve
@export var screen_shake_curve: Curve


const LASER_MIN_RANDOM_TIME_UPPER_HEALTH: float = 6.0
const LASER_MAX_RANDOM_TIME_UPPER_HEALTH: float = 10.0

const LASER_MIN_RANDOM_TIME_LOWER_HEALTH: float = 15.0
const LASER_MAX_RANDOM_TIME_LOWER_HEALTH: float = 20.0

const LASER_LENGTH: float = 256.0

var spinner_mat: ShaderMaterial = preload("res://mat/mat_spinner.tres")
var spinner_damage_mat: ShaderMaterial = preload("res://mat/mat_spinner_damagepart.tres")

enum BossState {
	DEAD,
	CENTER,
	CHASING,
}

enum BossAttack { 
	LASER
}

var state: BossState

var max_health: float
var health: float

var time: float = 0.0 
var amt: float = 0.0
var FADE_RATE: float = 4.0

var laser_cooldown: float = 15.0
var spike_time: float = 0.0

var CHASE_SPEED: float = 15.0

var SPIKE_COOLDOWN: float = 10.0
var spike_cooldown: float = 2.0

var laser_fired: bool
const LASER_DELAY: float = 0.47
var laser_lifetime: float
var laser_delay: float

var went_to_center: bool = false
var CENTER_POS: Vector3 = Vector3(0, 10, 0) 
var center_time: float = 0.0
var center_rotation: float = 0.0

func _ready() -> void:
	laser_fired = true
	laser_delay = -LASER_DELAY
	laser_lifetime = 110.0
	max_health = 1500
	health = max_health
	state = BossState.CHASING
	spikes.global_position.y = SPIKES_MIN_HEIGHT
	HUD.boss_health_bar.max_value = max_health
	HUD.update_boss_health(max_health)
	line = line_3d.instantiate()
	add_child(line)
	spinner_killer.disabled = true
	line.set_camera(get_viewport().get_camera_3d())
	spinner_mat.set_shader_parameter("alpha" , 0)
	spinner_damage_mat.set_shader_parameter("alpha", 0)

func goto_center() -> void:
	state = BossState.CENTER
	went_to_center = true

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
	
	time += delta
	laser_cooldown -= delta
	
	spike_cooldown -= delta
	laser_delay -= delta
	laser_lifetime += delta
	
	
	var T: float = remap(laser_delay, LASER_DELAY, -LASER_DELAY, 0.0, 1.0)
	var squish: float = laser_animate_curve.sample(T) - 0.5
	scale = Vector3(1 - squish, 1 + squish, 1 - squish)
	
	
	var perma_spikes: bool = health <= max_health * 0.1
	if perma_spikes:
		if spike_time >= 0.5:
			spike_time -= delta
	else:
		spike_time -= delta
		
	if spike_cooldown <= 0:
		Character.sfx_boss_spikes.play()
		spike_time = 2.9
		if perma_spikes:
			spike_cooldown = 99999.9
		else:
			spike_cooldown = SPIKE_COOLDOWN
	
	if spike_time > 0:
		var T2: float = remap(spike_time, 1.0, 0.0, 0.0, 1.0)
		var height_T: = spike_curve.sample(T2)
		var height = remap(height_T, 0.0, 1.0, SPIKES_MIN_HEIGHT, SPIKES_MAX_HEIGHT)
		spikes.global_position.y = height
	
	if not laser_fired and laser_delay <= 0.0:
		fire_laser()
	

	
	if laser_cooldown <= 0:
		Character.sfx_boss_laser.play()
		laser_fired = false
		laser_delay = LASER_DELAY
		var min_time_scaled = remap(health, 0, max_health, LASER_MIN_RANDOM_TIME_UPPER_HEALTH, LASER_MIN_RANDOM_TIME_LOWER_HEALTH)
		var max_time_scaled = remap(health, 0, max_health, LASER_MAX_RANDOM_TIME_UPPER_HEALTH, LASER_MAX_RANDOM_TIME_LOWER_HEALTH)
		laser_cooldown = randf_range(min_time_scaled, max_time_scaled)

	if health <= max_health * 0.5 and not went_to_center:
		goto_center()
		
	match state:
		BossState.CHASING:
			var dir: Vector3 = global_position.direction_to(Character.global_position)
			global_position += dir * CHASE_SPEED * delta
			global_position.y = max(5.0, global_position.y)
			spinner_killer.disabled = true
		BossState.CENTER:
			if health <= max_health * 0.333:
				state = BossState.CHASING
				Character.sfx_boss_spinner.stop()
				spinner_mat.set_shader_parameter("alpha" , 0)
				spinner_damage_mat.set_shader_parameter("alpha" , 0)
				return
			
			center_time += delta * 0.333
			var t: float = pow(0.5, delta * 5.0)
			global_position = lerp(CENTER_POS, global_position, t)
			var period: float = center_time - ((center_time as int) as float)
			if period < 0.1:
				Character.sfx_boss_spinner.play()
			spinner_mat.set_shader_parameter("alpha" , center_indicator_alpha.sample(period))
			var dmg_alpha: float = center_pillar_alpha.sample(period)
			spinner_killer.disabled = dmg_alpha < 0.5
			spinner_damage_mat.set_shader_parameter("alpha" , dmg_alpha)
			var spin_rate: float = center_spin_rate.sample(period)
			spinner.rotate_y(spin_rate * delta)
			Camera.trauma = screen_shake_curve.sample(period)
		
func fire_laser() -> void:
	laser_fired = true
	var dir: Vector3 = global_position.direction_to(Character.global_position)
	line.points[0] = global_position
	line.points[1] = global_position + dir * LASER_LENGTH
	laser_lifetime = 0.0
	laser_damage.disabled = false
	laser_damage.skip_frames = 3
	laser_parry.global_position = global_position
	laser_parry.look_at(Character.global_position)
	laser_damage.global_position = global_position
	laser_damage.look_at(Character.global_position)
	Camera.trauma = 1.0

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

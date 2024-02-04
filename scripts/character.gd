extends CharacterBody3D

const EPSILON: float = 0.001
const FRICTION: float = 4.0
const STOP_SPEED: float = 10.0

const SPEED_CAP: float = 1000.0
const SPEED: float = 12.0
const ACCELERATE: float = 15.0

@export var auto_kickback: float
@export var shotgun_kickback: float
@export var sniper_kickback: float
@export var jump_height: float
@export var jump_time_to_peak: float
@export var dash_distance: float
@export var min_dash_speed: float

var JUMP_VEL: float
var GRAVITY: float

@onready var camera: Camera = $Camera3D
@onready var fire_pos: Marker3D = $FirePos

@onready var sfx_sniper_shoot: AudioStreamPlayer = $Sounds/SniperShoot
@onready var sfx_sniper_charge: AudioStreamPlayer = $Sounds/SniperCharge
@onready var sfx_auto: AudioStreamPlayer = $Sounds/Auto
@onready var sfx_shotgun: AudioStreamPlayer = $Sounds/Shotgun
@onready var sfx_dash: AudioStreamPlayer = $Sounds/Dash
@onready var sfx_dash_cooldown: AudioStreamPlayer = $Sounds/DashCooldown
@onready var sfx_dryfire: AudioStreamPlayer = $Sounds/Dryfire
@onready var sfx_parry: AudioStreamPlayer = $Sounds/Parry
@onready var sfx_parry_miss: AudioStreamPlayer = $Sounds/ParryMiss

var grounded: bool = false
var is_auto_out_of_ammo_flag: bool = false
var just_spawned: int = 2

signal parry

func _ready() -> void:
	JUMP_VEL = 2.0 * jump_height / jump_time_to_peak
	GRAVITY = (-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	Controls.connect("entered_scope", _entered_scope)
	Controls.connect("exited_scope", _exited_scope)
	#PitchChanger.register_inverse_player(sfx_sniper_shoot)
	PitchChanger.register_inverse_player(sfx_sniper_charge)
	#PitchChanger.register_inverse_player(sfx_shotgun)
	
func _entered_scope() -> void:
	sfx_sniper_charge.play()
	
func _exited_scope() -> void:
	sfx_sniper_charge.stop()

func _process(_delta: float) -> void:
	if Menu.enabled: return
	
func _do_guns() -> void:
	var dir: Vector3 = -camera.global_basis.z
	var pitch_bullets: float = clampi(BulletServer.valid_bullets, 0, 128)
	
	if Controls.get_sniper_attack():
		sfx_sniper_shoot.pitch_scale = remap(BulletServer.bolt_damage, 0.0, 128.0, 1.25, 0.75)
		sfx_sniper_shoot.volume_db = remap(BulletServer.bolt_damage, 0.0, 128.0, -1, 5)
		sfx_sniper_shoot.play()
		BulletServer.fire_sniper(camera.global_position, dir)
		velocity = -dir * sniper_kickback
		
	if Controls.get_auto_attack():
		if BulletServer.fire_auto(fire_pos.global_position, dir):
			if not is_on_floor():
				velocity -= dir * auto_kickback 
			sfx_auto.pitch_scale = remap(pitch_bullets, 128.0, 0.0, 2.0, 1.0)
			sfx_auto.play()
		elif not is_auto_out_of_ammo_flag:
			sfx_dryfire.play()
			is_auto_out_of_ammo_flag = true
			
	elif Controls.get_shotgun_attack():
		var result: int = BulletServer.fire_shotgun(fire_pos.global_position, dir)
		if result != 0:
			var knockback: float = shotgun_kickback
			sfx_shotgun.pitch_scale = remap(pitch_bullets, 128.0, 0.0, 1.0, 0.5)
			if result == 1:
				knockback /= 2
			velocity -= dir * knockback
			sfx_shotgun.play()	
		else:
			sfx_dryfire.play()
			
	if BulletServer.valid_bullets > 0:
		is_auto_out_of_ammo_flag = false


func _physics_process(delta: float) -> void:
	
	if Menu.enabled: return
	if Controls.is_dead: return
	
	var wish_dir: Vector3 = get_wish_dir()
	
	if is_on_floor() and Controls.wish_jump:
		velocity.y = JUMP_VEL
		grounded = false
	
	accelerate(wish_dir, delta)
	
	if grounded:
		friction(delta)
	
	var old_pos: Vector3 = global_transform.origin
	
	velocity.y += GRAVITY * delta;
	var flat_vel := Vector3(velocity.x, 0, velocity.z)
	
	var did_dash: int = Controls.try_dash()
	
	if did_dash == 1:
		var dash_speed: float = maxf(flat_vel.length(), min_dash_speed)
		if wish_dir != Vector3.ZERO:
			global_transform.origin += wish_dir * dash_distance
			velocity = wish_dir * dash_speed
		else:
			var forward: Vector3 = -camera.global_transform.basis.z
			forward.y = 0
			forward = forward.normalized()
			global_transform.origin += forward * dash_distance
			velocity = forward.normalized() * dash_speed
		sfx_dash.play()
	elif did_dash == 2:
		sfx_dash_cooldown.play()

	if flat_vel.length() > SPEED_CAP:
		flat_vel = flat_vel.normalized() * SPEED_CAP
		velocity = Vector3(flat_vel.x, velocity.y, flat_vel.z)
	
	if Controls.get_try_parry():
		var parry_area: Area3D = Character.get_node("Camera3D/ParryArea") as Area3D
		var overlapping: Array[Area3D] = parry_area.get_overlapping_areas()
		if overlapping.size() > 0:
			for area: Area3D in overlapping:
				area.emit_signal("parried")
			emit_signal("parry")
			Controls.freeze_frames = Controls.FREEZE_FRAME_MS
			
			sfx_parry.play()
		else:
			sfx_parry_miss.play()
	
	move_and_slide()
	
	_do_guns()
	
	if did_dash == 1:
		camera.dash_cam(old_pos)
	
	grounded = is_on_floor()
	
	just_spawned -= 1
	


func reset() -> void:
	sfx_sniper_charge.stop()
	just_spawned = 3
	is_auto_out_of_ammo_flag = false
	global_position = Vector3(0, 1, 25)
	velocity = Vector3.ZERO
	$Camera3D.rotation = Vector3(0,0,0)
	Camera.has_saved_last_view_angle_before_death = false
	move_and_slide()

func get_wish_dir() -> Vector3:
	var move_input: Vector2 = Controls.get_move_input().normalized()
	var forward: Vector3 = -camera.global_transform.basis.z
	var right: Vector3 = camera.global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	return Vector3(
		forward.x * move_input.y + right.x * move_input.x, 0,
		forward.z * move_input.y + right.z * move_input.x)

func accelerate(wish_dir: Vector3, delta: float) -> void:
	var curret_speed: float = velocity.dot(wish_dir)
	var add_speed: float = SPEED - curret_speed
	if add_speed <= 0:
		return
	var accel_speed: float = ACCELERATE * delta * SPEED
	if accel_speed > add_speed:
		accel_speed = add_speed
	velocity += accel_speed * wish_dir
	
func friction(delta: float) -> void:
	var speed: float = velocity.length()
	if speed < EPSILON:
		velocity = Vector3.ZERO
		return
	var control: float = maxf(STOP_SPEED, speed)
	var drop: float = control * FRICTION * delta
	velocity *= maxf(speed - drop, 0) / speed

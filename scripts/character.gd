extends CharacterBody3D

const EPSILON: float = 0.001
const FRICTION: float = 4.0
const STOP_SPEED: float = 10.0

const SPEED_CAP: float = 1000.0
const SPEED: float = 12.0
const ACCELERATE: float = 15.0

#const JUMP_HEIGHT: float = 4.25
#const JUMP_TIME_TO_PEAK: float = 0.4

@export var auto_kickback: float
@export var shotgun_kickback: float
@export var jump_height: float
@export var jump_time_to_peak: float
@export var dash_distance: float

var JUMP_VEL: float
var GRAVITY: float

@onready var camera: Camera = $Camera3D
@onready var fire_pos: Marker3D = $FirePos

@onready var sfx_sniper_shoot: AudioStreamPlayer = $Sounds/SniperShoot
@onready var sfx_sniper_charge: AudioStreamPlayer= $Sounds/SniperCharge
@onready var sfx_autopool: AudioStreamPlayer = $Sounds/Auto
@onready var sfx_shotgun: AudioStreamPlayer= $Sounds/Shotgun
@onready var sfx_dash: AudioStreamPlayer= $Sounds/Dash

const bb: PackedScene = preload("res://scenes/bb.tscn")

var grounded: bool = false

func _ready() -> void:
	JUMP_VEL = 2.0 * jump_height / jump_time_to_peak
	GRAVITY = (-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	Controls.connect("entered_scope", _entered_scope)
	Controls.connect("exited_scope", _exited_scope)
	
func _entered_scope() -> void:
	sfx_sniper_charge.play()
	
func _exited_scope() -> void:
	sfx_sniper_charge.stop()

func _process(_delta: float) -> void:
	if Menu.enabled: return
		
	if Controls.get_sniper_attack():
		sfx_sniper_shoot.play()
		BulletServer.fire_sniper(global_transform.origin, -camera.global_basis.z)

	

func _physics_process(delta: float) -> void:
	if Menu.enabled: return
	
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
	
	if Controls.get_try_dash():
		if wish_dir != Vector3.ZERO:
			global_transform.origin += wish_dir * dash_distance
		elif flat_vel.length() > 0.25:
			global_transform.origin += flat_vel.normalized() * dash_distance
		else:
			var forward: Vector3 = -camera.global_transform.basis.z
			forward.y = 0
			forward = forward.normalized()
			global_transform.origin += forward * dash_distance
		sfx_dash.play()
	

	if flat_vel.length() > SPEED_CAP:
		flat_vel = flat_vel.normalized() * SPEED_CAP
		velocity = Vector3(flat_vel.x, velocity.y, flat_vel.z)
	
	move_and_slide()
	
	if Controls.get_try_dash():
		camera.dash_cam(old_pos)
	
	grounded = is_on_floor()
	
	if Controls.get_auto_attack():
		var dir: Vector3 = -camera.global_basis.z
		dir = Math.random_unit_vector_in_cone(dir, 0.25)
		BulletServer.fire_bullet(fire_pos.global_transform.origin, dir * 100)
		if not is_on_floor():
			velocity += camera.global_basis.z * auto_kickback
		sfx_autopool.play()
	
	if Controls.get_shotgun_attack():
		var dir: Vector3 = -camera.global_basis.z
		for _n in 25:
			BulletServer.fire_bullet(camera.global_transform.origin, Math.random_unit_vector_in_cone(dir, 5) * 100)
		var knockback: float = shotgun_kickback/2 if is_on_floor() else shotgun_kickback
		velocity += camera.global_basis.z * knockback
		sfx_shotgun.play()

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

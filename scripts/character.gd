extends CharacterBody3D

const EPSILON: float = 0.001
const FRICTION: float = 4.0
const STOP_SPEED: float = 10.0

const SPEED_CAP: float = 20.0
const SPEED: float = 12.0
const ACCELERATE: float = 15.0

const JUMP_HEIGHT: float = 4.25
const JUMP_TIME_TO_PEAK: float = 0.4
const JUMP_VEL: float = 2.0 * JUMP_HEIGHT / JUMP_TIME_TO_PEAK
const GRAVITY: float = (-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_PEAK * JUMP_TIME_TO_PEAK)

@onready var camera: Camera3D = $Camera3D
const bb: PackedScene = preload("res://scenes/bb.tscn")

var grounded: bool = false

func _physics_process(delta: float) -> void:
	var wish_dir: Vector3 = get_wish_dir()
	
	if is_on_floor() and Controls.wish_jump:
		velocity.y = JUMP_VEL
		grounded = false
	
	accelerate(wish_dir, delta)
	
	if grounded:
		friction(delta)
	
	velocity.y += GRAVITY * delta;
	
	var flat_vel := Vector3(velocity.x, 0, velocity.z)
	if flat_vel.length() > SPEED_CAP:
		flat_vel = flat_vel.normalized() * SPEED_CAP
		velocity = Vector3(flat_vel.x, velocity.y, flat_vel.z)
	
	move_and_slide()
	
	grounded = is_on_floor()
	
	if Controls.get_primary_attack():
		BulletServer.fire_bullet(global_transform.origin, -camera.global_basis.z * 100)
		velocity += camera.global_basis.z * 0.75

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

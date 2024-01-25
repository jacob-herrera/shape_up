extends Node3D

const MAX_BULLETS: int = 256
const BULLET_GRAV: float = -30.0
const BULLET_SPEED: float = 100.0
const NUM_SHOTGUN_BULLETS: int = 32
const SNIPER_RANGE: float = 500.0

const COLLECT_RANGE: float = 10.0

enum BulletState {DISABLED, PROJECTILE, COLLECTABLE, COLLECTING}



class Bullet extends Object:
	var state: BulletState
	var velocity: Vector3
	var mesh: MeshInstance3D
	var bounces: int
	var period: float
	
var bullets: Array[Bullet]
var valid_bullets: int = 256

var params: PhysicsRayQueryParameters3D
var space: PhysicsDirectSpaceState3D

@export var bb_mesh: PackedScene = preload("res://scenes/bb.tscn")
@export var line_3d: PackedScene = preload("res://scenes/line_3d.tscn")
var line: LineRenderer
var line_alpha: float = 1.0

@export_flags_3d_physics var mask: int
@onready var pop: AudioStreamPlayer = $Pop
	
func _enter_tree() -> void:
	space = get_world_3d().direct_space_state
	params = PhysicsRayQueryParameters3D.new()
	params.collision_mask = mask
	bullets = []
	line = line_3d.instantiate()
	add_child(line)
	for i in MAX_BULLETS:
		var mesh: MeshInstance3D = bb_mesh.instantiate() as MeshInstance3D
		add_child(mesh)
		mesh.visible = false
		mesh.global_transform.origin = Vector3(0, 2, 0)
		var bullet: Bullet = Bullet.new()
		bullet.state = BulletState.DISABLED
		bullet.mesh = mesh
		bullet.velocity = Vector3.ZERO
		bullet.bounces = 0
		bullets.push_back(bullet)
		
func _ready() -> void:
	line.set_camera(get_viewport().get_camera_3d())

func _exit_tree() -> void:
	for bullet: Bullet in bullets:
		bullet.free()

func _process(delta: float) -> void:
	if Menu.enabled: return
	
	line_alpha -= delta
	line_alpha = clampf(line_alpha, 0.0, 1.0)
	line.material.set_shader_parameter("alpha", line_alpha)
	for bullet: Bullet in bullets:
		if bullet.state == BulletState.PROJECTILE:
			bullet.velocity += Vector3(0, BULLET_GRAV * delta, 0)
			var start: Vector3 = bullet.mesh.global_transform.origin
			var end: Vector3 = start + (bullet.velocity * delta)
			params.from = start
			params.to = end
			var result: Dictionary = space.intersect_ray(params)
			if not result.is_empty():
				bullet.velocity = bullet.velocity.bounce(result.normal)
				bullet.velocity = bullet.velocity.normalized() * bullet.velocity.length() / 3
				bullet.bounces += 1
			else:
				bullet.mesh.global_transform.origin = end
				
			if bullet.bounces > 2:
				bullet.state = BulletState.COLLECTABLE
				bullet.mesh.global_transform.origin.y = 0
				bullet.period = -3 + randf()

	var char_pos: Vector3 = Character.global_transform.origin

	for bullet: Bullet in bullets:
		if bullet.state == BulletState.COLLECTABLE:
			bullet.period += delta * 2.0
			bullet.mesh.global_transform.origin.y = bob_ease(bullet.period)
			var dist: float = char_pos.distance_to(bullet.mesh.global_transform.origin)
			if dist < COLLECT_RANGE:
				bullet.state = BulletState.COLLECTING
				bullet.period = 0
				
	for bullet: Bullet in bullets:
		if bullet.state == BulletState.COLLECTING:
			bullet.period += delta
			var t: float = remap(bullet.period, 0.0, 0.25, 0.0, 1.0)
			bullet.mesh.global_transform.origin = lerp(bullet.mesh.global_transform.origin, char_pos - Vector3(0, 0.5, 0), t)
			if t >= 0.6:
				bullet.state = BulletState.DISABLED
				bullet.mesh.visible = false
				valid_bullets += 1
				pop.play()
	
func bob_ease(bob: float) -> float:
	if bob > 0:
		bob = sin(bob) / 4.0
		return bob + 0.5
	else:
		bob = clampf(bob, -1, 0)
		bob = remap(bob, -1, 0, 0.05, 0.5	)
		return bob
	
func _fire_bullet(pos: Vector3, dir: Vector3) -> void:
	for bullet: Bullet in bullets:
		if bullet.state == BulletState.DISABLED:
			bullet.state = BulletState.PROJECTILE
			bullet.mesh.visible = true 
			bullet.mesh.global_transform.origin = pos
			bullet.velocity = dir * BULLET_SPEED
			bullet.bounces = 0
			valid_bullets -= 1
			break
			
func fire_auto(pos: Vector3, dir: Vector3) -> bool:
	if valid_bullets == 0: return false
	var spread: Vector3 = Math.random_unit_vector_in_cone(dir, 0.25)
	_fire_bullet(pos, spread)
	return true
			
func fire_shotgun(pos: Vector3, dir: Vector3) -> int:
	if valid_bullets == 0: return 0
	var shots = clampi(valid_bullets, 1, NUM_SHOTGUN_BULLETS)
	for i in shots:
		var spread: Vector3 = Math.random_unit_vector_in_cone(dir, 6)
		_fire_bullet(pos, spread)
	if shots >= NUM_SHOTGUN_BULLETS / 2:
		return 2
	else:
		return 1

func fire_sniper(pos: Vector3, dir: Vector3) -> void:
	params.from = pos
	params.to = pos + dir * SNIPER_RANGE
	var result: Dictionary = space.intersect_ray(params)
	if result.is_empty(): return
	line.points[0] = params.from
	line.points[1] = result.position
	line_alpha = 1
	

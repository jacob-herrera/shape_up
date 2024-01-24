extends Node3D

const MAX_BULLETS: int = 1024
const BULLET_GRAV: float = -30.0

const SNIPER_RANGE: float = 500

enum BulletState {DISABLED, PROJECTILE, COLLECTABLE}

class Bullet extends Object:
	var state: BulletState
	var velocity: Vector3
	var mesh: MeshInstance3D
	var bounces: int
	var bob: float
	
var bullets: Array[Bullet]

var params: PhysicsRayQueryParameters3D
var space: PhysicsDirectSpaceState3D

@export var bb_mesh: PackedScene = preload("res://scenes/bb.tscn")
@export var line_3d: PackedScene = preload("res://scenes/line_3d.tscn")

var line: LineRenderer
var line_alpha: float = 1.0

@export_flags_3d_physics var mask: int
	
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
				bullet.bob = -3 + randf()

	for bullet: Bullet in bullets:
		if bullet.state == BulletState.COLLECTABLE:
			bullet.bob += delta * 2.0
			bullet.mesh.global_transform.origin.y = bob_ease(bullet.bob)

func bob_ease(bob: float) -> float:
	if bob > 0:
		bob = sin(bob) / 4.0
		return bob + 0.5
	else:
		bob = clampf(bob, -1, 0)
		bob = remap(bob, -1, 0, 0.05, 0.5	)
		return bob
	
 	

func fire_bullet(pos: Vector3, vel: Vector3) -> void:
	for bullet: Bullet in bullets:
		if bullet.state == BulletState.DISABLED:
			bullet.state = BulletState.PROJECTILE
			bullet.mesh.visible = true 
			bullet.mesh.global_transform.origin = pos
			bullet.velocity = vel
			bullet.bounces = 0
			break

func fire_sniper(pos: Vector3, dir: Vector3) -> void:
	params.from = pos
	params.to = pos + dir * SNIPER_RANGE
	var result: Dictionary = space.intersect_ray(params)
	if result.is_empty(): return
	line.points[0] = params.from
	line.points[1] = result.position
	line_alpha = 1
	

extends Node3D

const MAX_BULLETS: int = 1024
const BULLET_GRAV: float = -50.0

class Bullet extends Object:
	var active: bool
	var velocity: Vector3
	var mesh: MeshInstance3D
	
var bullets: Array[Bullet]

var params: PhysicsRayQueryParameters3D
var space: PhysicsDirectSpaceState3D

@export var bb_mesh: PackedScene = preload("res://scenes/bb.tscn")
	
func _enter_tree() -> void:
	space = get_world_3d().direct_space_state
	params = PhysicsRayQueryParameters3D.new()
	bullets = []
	for i in MAX_BULLETS:
		var mesh: MeshInstance3D = bb_mesh.instantiate() as MeshInstance3D
		add_child(mesh)
		mesh.visible = false
		mesh.global_transform.origin = Vector3(0, 2, 0)
		var bullet: Bullet = Bullet.new()
		bullet.active = false
		bullet.mesh = mesh
		bullet.velocity = Vector3.ZERO
		bullets.push_back(bullet)
		
func _exit_tree() -> void:
	for bullet: Bullet in bullets:
		bullet.free()

func _process(delta: float) -> void:
	for bullet: Bullet in bullets:
		if not bullet.active: continue
		bullet.velocity += Vector3(0, BULLET_GRAV * delta, 0)
		var start: Vector3 = bullet.mesh.global_transform.origin
		var end: Vector3 = start + (bullet.velocity * delta)
		params.from = start
		params.to = end
		var result: Dictionary = space.intersect_ray(params)
		if not result.is_empty():
			bullet.velocity = bullet.velocity.bounce(result.normal)
			bullet.velocity = bullet.velocity.normalized() * bullet.velocity.length() / 2
			bullet.mesh.global_transform.origin = result.position + Vector3(0, 0.01, 0)
		else:
			bullet.mesh.global_transform.origin = end
			
		if bullet.mesh.global_transform.origin.length() > 100 or bullet.velocity.length() < 1:
			bullet.active = false
			bullet.mesh.visible = false

func fire_bullet(pos: Vector3, vel: Vector3) -> void:
	for bullet: Bullet in bullets:
		if bullet.active == false:
			bullet.active = true
			bullet.mesh.visible = true 
			bullet.mesh.global_transform.origin = pos
			bullet.velocity = vel
			break

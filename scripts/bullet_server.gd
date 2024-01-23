extends Node3D

const MAX_BULLETS: int = 1024
const BULLET_GRAV: float = -30.0

const SNIPER_RANGE: float = 500

class Bullet extends Object:
	var active: bool
	var velocity: Vector3
	var mesh: MeshInstance3D
	var bounces: int
	
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
		bullet.active = false
		bullet.mesh = mesh
		bullet.velocity = Vector3.ZERO
		bullet.bounces = 0
		bullets.push_back(bullet)
		
func _ready() -> void:
	#var cam: Camera3D = get_viewport().get_camera_3d()
	line.set_camera(get_viewport().get_camera_3d())

func _exit_tree() -> void:
	for bullet: Bullet in bullets:
		bullet.free()

func _process(delta: float) -> void:
	line_alpha -= delta
	line_alpha = clampf(line_alpha, 0.0, 1.0)
	line.material.set_shader_parameter("alpha", line_alpha)
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
			bullet.velocity = bullet.velocity.normalized() * bullet.velocity.length() / 4
			#bullet.mesh.global_transform.origin = result.position
			bullet.bounces += 1
		else:
			bullet.mesh.global_transform.origin = end
			
		if bullet.bounces > 3:
			bullet.active = false
			bullet.mesh.visible = false

func fire_bullet(pos: Vector3, vel: Vector3) -> void:
	for bullet: Bullet in bullets:
		if bullet.active == false:
			bullet.active = true
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
	

extends Node3D

const MAX_BULLETS: int = 1024

class Bullet extends Object:
	var active: bool
	var velocity: Vector3
	var mesh: MeshInstance3D
	
var bullets: Array[Bullet]

@export var bb_mesh: PackedScene = preload("res://scenes/bb.tscn")
	
func _enter_tree() -> void:
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
		var motion: Vector3 = bullet.velocity * delta
		bullet.mesh.global_transform.origin += motion
		if bullet.mesh.global_transform.origin.length() > 100:
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

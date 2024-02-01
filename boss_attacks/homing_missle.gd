extends Node3D

@export var speed: float
#var target: Transform3D

func _process(delta: float) -> void:
	#if target != null:
	var target: Transform3D = Character.transform
	var dir: Vector3 = (target.origin - global_position).normalized()
	global_position += dir * speed * delta
	look_at(target.origin)

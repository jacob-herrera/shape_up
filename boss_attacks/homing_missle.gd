extends Node3D

@export var speed: float

func _process(delta: float) -> void:
	var target: Transform3D = Character.transform
	var dir: Vector3 = target.origin.direction_to(global_position)
	global_position += dir * speed * delta
	look_at(target.origin)

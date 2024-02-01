extends Node3D

@export var speed: float

func _process(delta: float) -> void:
	var target: Transform3D = Character.transform
	var dir: Vector3 = global_position.direction_to(target.origin)
	global_position += dir * speed * delta
	look_at(target.origin)

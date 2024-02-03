extends Node3D

@export var speed: float

@export var delay: float

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	if time <= delay: return
	var target: Vector3 = Character.global_position
	var dir: Vector3 = global_position.direction_to(target)
	look_at(target)
	global_position += dir * speed * delta

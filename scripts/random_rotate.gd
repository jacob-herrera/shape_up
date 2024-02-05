extends Node3D

@export var axis_x: bool = true
@export var axis_y: bool = true
@export var axis_z: bool = true 

func _process(delta: float) -> void:
	if axis_x:
		rotate_x(delta)
	if axis_y:
		rotate_y(delta)
	if axis_z:
		rotate_z(delta)

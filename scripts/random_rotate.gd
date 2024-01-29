extends Node3D

func _process(delta: float) -> void:
	rotate_x(delta)
	rotate_y(delta)
	rotate_z(delta)

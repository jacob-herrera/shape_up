extends MeshInstance3D

func _process(_delta: float) -> void:
	var target_pos: Vector3 = get_parent().global_transform.origin
	target_pos.y = 0.01
	global_transform.origin = target_pos

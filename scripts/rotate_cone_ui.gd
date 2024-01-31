extends Node3D

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	#var offset: float = sin(time * 5.0) / 4.0
	#global_transform.origin = Vector3(0, offset, 0)
	rotation.x = time * 2.0
	rotation.y = time * 2.0
	rotation.z = time * 2.0

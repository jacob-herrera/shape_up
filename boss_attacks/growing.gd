extends Node3D

@export var col: CollisionShape3D
@export var mesh: MeshInstance3D

@export var grow_rate: float

var grow_vec: Vector3

func _ready() -> void:
	grow_vec = Vector3(grow_rate, grow_rate, grow_rate) 

func _process(delta: float) -> void:
	col.scale += grow_vec * delta
	mesh.scale += grow_vec * delta

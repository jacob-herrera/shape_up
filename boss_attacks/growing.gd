extends Node3D

@export var col: CollisionShape3D
@export var mesh: MeshInstance3D

@export var grow_rate: float
@export var max_life_time: float
@export var delay: float

var life_time: float = 0.0
var grow_vec: Vector3
var sfx_flag: bool = false

func _ready() -> void:
	grow_vec = Vector3(grow_rate, grow_rate, grow_rate) 

func _process(delta: float) -> void:
	life_time += delta
	if life_time <= delay:
		return
	
	if sfx_flag == false:
		sfx_flag = true
		$explosion.play()
		$noise.play()
	
	col.scale += grow_vec * delta
	mesh.scale += grow_vec * delta
	if life_time >= max_life_time:
		queue_free()

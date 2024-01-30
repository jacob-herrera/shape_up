extends Area3D

const DAMAGING_COLLIDER_LAYER: int = 4
const PLAYER_LAYER: int = 2

func _process(delta: float) -> void:
	var overlap: bool = has_overlapping_bodies()
	if overlap:
		Controls.invoke_player_death()

func _ready() -> void:
	collision_mask = PLAYER_LAYER
	collision_layer = DAMAGING_COLLIDER_LAYER

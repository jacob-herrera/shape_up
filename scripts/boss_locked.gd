extends Node3D

@onready var mat: ShaderMaterial = preload("res://mat/faded_out.tres")

func _ready() -> void:
	if not Leaderboard.boss2_unlocked:
		$Mesh.material_override = mat
		%Hurtbox.queue_free()

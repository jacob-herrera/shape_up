extends Node3D

@onready var missile: PackedScene = preload("res://boss_attacks/homing_missile.tscn")

var num_missiles: int
var cooldown: float

var spawned_final: bool
var final_missile: Node3D

func _ready() -> void:
	spawned_final = false
	num_missiles = 3
	cooldown = 2.0
	spawn_missile()

func spawn_missile() -> void:
	num_missiles -= 1
	
	var new: Node3D = missile.instantiate()
	add_child(new)
	new.global_position = global_position
	
	if num_missiles == 0:
		final_missile = new
		spawned_final = true
	
func _process(delta: float) -> void:
	if spawned_final:
		if final_missile == null:
			SceneManager.goto_lobby()
	if num_missiles > 0:
		cooldown -= delta
		if cooldown <= 0.0:
			cooldown = 3.0
			spawn_missile()


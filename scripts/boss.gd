extends Node3D
class_name Boss

@onready var mat: ShaderMaterial = $Visual/Mesh.material_override
@onready var visual: Node3D = $Visual

@onready var growing_circle: PackedScene = preload("res://boss_attacks/growing_circle.tscn")
@onready var missle: PackedScene = preload("res://boss_attacks/homing_missile.tscn")
@onready var chaser: PackedScene = preload("res://boss_attacks/chaser.tscn")

var RNG := RandomNumberGenerator.new()

var alive_time: float = 0.0 
var amt: float = 0.0
var FADE_RATE: float = 4.0
const SHAKE_STRENGTH: float = 0.5

enum BossState {
	EXPLOSION,
	MISSILE
}

var state: BossState = BossState.EXPLOSION
var state_time: float = 1.0

const MAX_HEALTH: int = 2000
var health: int = MAX_HEALTH
var spawned_chaser: bool = false


var center_pos: Vector3 = Vector3(0.0, 5.25, 0.0)

func _ready() -> void:
	HUD.boss_health_bar.max_value = MAX_HEALTH

func spawn_chaser() -> void:
	var new: Node3D = chaser.instantiate()
	add_child(new)
	new.global_position = global_position

func handle_state() -> void:
	match state:
		BossState.EXPLOSION:
			var new: Node3D = growing_circle.instantiate()
			add_child(new)
			var pos: Vector3 = Vector3(randf_range(-62.5, 62.5), 0, randf_range(-62.5, 62.5))
			new.global_position = pos
		BossState.MISSILE:
			var new: Node3D = missle.instantiate()
			add_child(new)
			new.global_position = global_position

func move_boss() -> void:
	spawned_chaser = true
	var origin := Transform3D(Basis.IDENTITY, center_pos)
	var rot := Transform3D.IDENTITY.rotated(Vector3.UP, alive_time)
	var height: float = sin(alive_time) * 3 + 1
	var trans := Transform3D.IDENTITY.translated(Vector3(0, height, 10))
	global_transform = origin * rot * trans


func _process(delta: float) -> void:
	if Menu.enabled or Controls.is_dead: return 
	
	HUD.update_boss_health(health)
	amt -= delta * FADE_RATE
	#var amt = 
	mat.set_shader_parameter("amt", clampf(amt, 0.0, 1.0))
	var strength: float = remap(clampf(amt, 0.0, 1.0), 0.0, 1.0, 0, SHAKE_STRENGTH)
	var shake_vec := Vector3(RNG.randf_range(-strength, strength), RNG.randf_range(-strength, strength) , RNG.randf_range(-strength, strength))
	visual.global_position = global_position + shake_vec
	
	alive_time += delta
	
	move_boss()
	
	state_time -= delta
	
	if health <= MAX_HEALTH / 2.0:
		spawn_chaser()
	
	if state_time <= 0:
		state = randi_range(0, 1) as BossState
		state_time = 1.0
		handle_state()
	

func _on_hit(dmg: int) -> void:
	health -= dmg
	amt = 1.25
	

extends Node3D
class_name Boss

@onready var mat: ShaderMaterial = $Visual/Mesh.material_override
@onready var visual: Node3D = $Visual

var RNG := RandomNumberGenerator.new()

var amt: float = 0.0
var FADE_RATE: float = 4.0
const SHAKE_STRENGTH: float = 0.5

var health: int = 2000

var pos: Vector3 = Vector3(0.0, 5.25, 0.0)

func _ready() -> void:
	HUD.boss_health_bar.max_value = 2000

func _process(delta: float) -> void:
	if Menu.enabled or Controls.is_dead: return 
	
	HUD.update_boss_health(health)
	amt -= delta * FADE_RATE
	#var amt = 
	mat.set_shader_parameter("amt", clampf(amt, 0.0, 1.0))
	var strength: float = remap(clampf(amt, 0.0, 1.0), 0.0, 1.0, 0, SHAKE_STRENGTH)
	var shake_vec := Vector3(RNG.randf_range(-strength, strength), RNG.randf_range(-strength, strength) , RNG.randf_range(-strength, strength))
	visual.global_position = pos + shake_vec

func _on_hit(dmg: int) -> void:
	health -= dmg
	amt = 1.25
	

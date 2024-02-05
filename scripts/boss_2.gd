extends Node3D

@onready var mat: ShaderMaterial = $Visual/Mesh.material_override
@onready var visual: Node3D = $Visual

var RNG := RandomNumberGenerator.new()
const SHAKE_STRENGTH: float = 0.5

var max_health: float
var health: float

var time: float = 0.0 
var amt: float = 0.0
var FADE_RATE: float = 4.0

func _ready() -> void:
	max_health = 2000
	health = max_health
	HUD.boss_health_bar.max_value = max_health
	HUD.update_boss_health(max_health)

func _process(delta: float) -> void:
	if Menu.enabled or Controls.is_dead: return 
	
	amt -= delta * FADE_RATE
	mat.set_shader_parameter("amt", clampf(amt, 0.0, 1.0))
	
	
func _on_hit(dmg: int) -> void:
	health -= dmg
	health = max(0, health)
	amt = 1.25
	HUD.shake_health()
	Character.sfx_hit.play()
	HUD.update_boss_health(health)

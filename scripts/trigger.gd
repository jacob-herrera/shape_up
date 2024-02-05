extends Node3D

enum OnTrigger {
	GOTO_BOSS_1,
	GOTO_LOBBY,
	GOTO_TUTORIAL_1,
	GOTO_TUTORIAL_2,
	GOTO_TUTORIAL_3,
	GOTO_TUTORIAL_4,
	GOTO_TUTORIAL_5,
	GOTO_TUTORIAL_6,
	GOTO_BOSS_2,
	GOTO_DIFFICULTY,
	SELECT_EASY,
	SELECT_MEDIUM,
	SELECT_HARD,
}

@onready var mat: ShaderMaterial = $Visual/Mesh.material_override

@export var on_trigger: OnTrigger
@export var max_hp: int = 64

var hp: float
var amt: float

func _ready() -> void:
	hp = max_hp
	amt = 0.0

func _process(delta: float) -> void:
	amt -= delta * 4.0
	mat.set_shader_parameter("amt", clampf(amt, 0.0, 1.0))
	
	var size: float = remap(hp, max_hp, 0, 0.5, 1.0)
	scale = Vector3(size, size, size)

	if hp <= 0:
		hp = max_hp
		match on_trigger:
			OnTrigger.GOTO_BOSS_1:
				SceneManager.goto_boss_1()
			OnTrigger.GOTO_LOBBY:
				SceneManager.goto_lobby()
			OnTrigger.GOTO_TUTORIAL_1:
				SceneManager.goto_tutorial1()
			OnTrigger.GOTO_TUTORIAL_2:
				SceneManager.goto_tutorial2()
			OnTrigger.GOTO_TUTORIAL_3:
				SceneManager.goto_tutorial3()
			OnTrigger.GOTO_TUTORIAL_4:
				SceneManager.goto_tutorial4()
			OnTrigger.GOTO_TUTORIAL_5:
				SceneManager.goto_tutorial5()
			OnTrigger.GOTO_TUTORIAL_6:
				SceneManager.goto_tutorial6()
			OnTrigger.GOTO_BOSS_2:
				SceneManager.goto_boss_2()
			OnTrigger.GOTO_DIFFICULTY:
				SceneManager.goto_difficulty()
			OnTrigger.SELECT_EASY:
				SceneManager.difficulty = SceneManager.Difficulty.EASY
				SceneManager.goto_lobby()
			OnTrigger.SELECT_MEDIUM:
				SceneManager.difficulty = SceneManager.Difficulty.MEDIUM
				SceneManager.goto_lobby()
			OnTrigger.SELECT_HARD:
				SceneManager.difficulty = SceneManager.Difficulty.HARD
				SceneManager.goto_lobby()
	
func _on_hit(dmg: int) -> void:
	hp -= dmg
	amt = 1
	Character.sfx_hit.play()

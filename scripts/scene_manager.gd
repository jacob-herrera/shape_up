extends Node

@onready var boss_1: PackedScene = preload("res://scenes/level_test.tscn")
@onready var boss_2: PackedScene = preload("res://scenes/boss_2.tscn")
@onready var lobby: PackedScene = preload("res://scenes/lobby.tscn")

@onready var tutorial_1: PackedScene = preload("res://scenes/tutorial_1.tscn")
@onready var tutorial_2: PackedScene = preload("res://scenes/tutorial_2.tscn")
@onready var tutorial_3: PackedScene = preload("res://scenes/tutorial_3.tscn")
@onready var tutorial_4: PackedScene = preload("res://scenes/tutorial_4.tscn")
@onready var tutorial_5: PackedScene = preload("res://scenes/tutorial_5.tscn")
@onready var tutorial_6: PackedScene = preload("res://scenes/tutorial_6.tscn")


var scene: Scene = Scene.BOSS_2

enum Scene {
	BOSS_1,
	BOSS_2,
	LOBBY,
	TUTORIAL_1,
	TUTORIAL_2,
	TUTORIAL_3,
	TUTORIAL_4,
	TUTORIAL_5,
	TUTORIAL_6,
}

func goto_lobby() -> void:
	get_tree().change_scene_to_packed(lobby)
	scene = Scene.LOBBY
	Controls.hard_reset()

func goto_boss_1() -> void:
	get_tree().change_scene_to_packed(boss_1)
	scene = Scene.BOSS_1
	Controls.hard_reset()

func goto_boss_2() -> void:
	get_tree().change_scene_to_packed(boss_2)
	scene = Scene.BOSS_2
	Controls.hard_reset()

func goto_tutorial1() -> void:
	get_tree().change_scene_to_packed(tutorial_1)
	scene = Scene.TUTORIAL_1
	Controls.hard_reset()
	
func goto_tutorial2() -> void:
	get_tree().change_scene_to_packed(tutorial_2)
	scene = Scene.TUTORIAL_2
	Controls.hard_reset()
	
func goto_tutorial3() -> void:
	get_tree().change_scene_to_packed(tutorial_3)
	scene = Scene.TUTORIAL_3
	Controls.hard_reset()
	
func goto_tutorial4() -> void:
	get_tree().change_scene_to_packed(tutorial_4)
	scene = Scene.TUTORIAL_4
	Controls.hard_reset()
	
func goto_tutorial5() -> void:
	get_tree().change_scene_to_packed(tutorial_5)
	scene = Scene.TUTORIAL_5
	Controls.hard_reset()
	
func goto_tutorial6() -> void:
	get_tree().change_scene_to_packed(tutorial_6)
	scene = Scene.TUTORIAL_6
	Controls.hard_reset()
	


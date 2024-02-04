extends Node

@onready var boss_1: PackedScene = preload("res://scenes/level_test.tscn")
@onready var lobby: PackedScene = preload("res://scenes/lobby.tscn")

var scene: Scene = Scene.BOSS_1

enum Scene {
	BOSS_1,
	LOBBY,
}

func goto_lobby() -> void:
	var tree: SceneTree = get_tree()
	tree.change_scene_to_packed(lobby)
	scene = Scene.LOBBY
	Controls.hard_reset()

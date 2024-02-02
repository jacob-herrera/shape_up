extends Node

var _players: Array[AudioStreamPlayer]
var _inverse_players: Array[AudioStreamPlayer]
#var _players3d: Array[AudioS]

func register_player(player: AudioStreamPlayer) -> void:
	_players.push_back(player)

func register_inverse_player(player: AudioStreamPlayer) -> void:
	_inverse_players.push_back(player)	
	
func _process(_dt: float) -> void:
	if Menu.enabled:
		for player: AudioStreamPlayer in _players:
			player.stream_paused = true
		for player: AudioStreamPlayer in _inverse_players:
			player.stream_paused = true
		return
	
	if Controls.is_dead:
		for player: AudioStreamPlayer in _players:
			player.stop()
		for player: AudioStreamPlayer in _inverse_players:
			player.stop()
		for player3d: AudioStreamPlayer3D in get_tree().get_nodes_in_group("player3d"):
			player3d.stop()
	else:
		for player: AudioStreamPlayer in _players:
			player.stream_paused = false
			player.pitch_scale = Controls.clock_speed
		for player: AudioStreamPlayer in _inverse_players:
			player.stream_paused = false
			player.pitch_scale = 1.0 / Controls.clock_speed
			 
		for player3d: AudioStreamPlayer3D in get_tree().get_nodes_in_group("player3d"):
			player3d.pitch_scale = 1.0 / Controls.clock_speed

extends Node

var _players: Array[AudioStreamPlayer]
var _inverse_players: Array[AudioStreamPlayer]

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
	
	for player: AudioStreamPlayer in _players:
		player.stream_paused = false
		player.pitch_scale = Controls.clock_speed

	for player: AudioStreamPlayer in _inverse_players:
		player.stream_paused = false
		player.pitch_scale = 1.0 / Controls.clock_speed

extends Node

var _players: Array[AudioStreamPlayer]
var _inverse_players: Array[AudioStreamPlayer]

func register_player(player: AudioStreamPlayer) -> void:
	_players.push_back(player)

func register_inverse_player(player: AudioStreamPlayer) -> void:
	_inverse_players.push_back(player)	
	
func _process(_dt: float) -> void:
	for player: AudioStreamPlayer in _players:
		player.pitch_scale = Controls.clock_speed

	for player: AudioStreamPlayer in _inverse_players:
		player.pitch_scale = 1.0 / Controls.clock_speed

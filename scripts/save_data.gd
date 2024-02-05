extends Node

var config: ConfigFile

const SAVE_PATH: String = "user://shapeup_savedata.cfg"

var time_sec: String = "TIME TABLE"

func _populate_config():
	for difficulty in 3:
		for boss in 2:
			for placement in 3:
				var s := "%d_%d_%d" % [difficulty, boss, placement]
				config.set_value(time_sec, s, 0)

func read_config():
	for difficulty in 3:
		for boss in 2:
			for placement in 3:
				var s := "%d_%d_%d" % [difficulty, boss, placement]
				var time: float = config.get_value(time_sec, s)
				Leaderboard.highscores[difficulty][boss][placement] = time

func save_config():
	if not OS.has_feature("windows"):
		return
		
	for difficulty in 3:
		for boss in 2:
			for placement in 3:
				var s := "%d_%d_%d" % [difficulty, boss, placement]
				var time: float = Leaderboard.highscores[difficulty][boss][placement]
				config.set_value(time_sec, s, time)
				
	var err = config.save(SAVE_PATH)
	if err != OK:
		print("failed saving")
		return

func _ready() -> void:
	if not OS.has_feature("windows"):
		return
	
	config = ConfigFile.new()

	var err = config.load(SAVE_PATH)
	if err != OK:
		_populate_config()
		return
		
	read_config()
	

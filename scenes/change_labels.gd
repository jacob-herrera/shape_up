extends Node3D

@onready var BestTimes: Label3D = $BestTimes
@onready var BestTimes2: Label3D = $BestTimes2

func _ready():
	var scores = Leaderboard.highscores
	BestTimes.text = "%s %.3f %.3f %.3f" % ["Time:", scores[0][0], scores[0][1], scores[0][2]]
	BestTimes2.text = "%s %.3f %.3f %.3f" % ["Time:", scores[1][0], scores[1][1], scores[1][2]]

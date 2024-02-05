extends Node3D

#@onready var BestTimes: Label3D = $BestTimes
#@onready var BestTimes2: Label3D = $BestTimes2

func _ready():
	var scores = Leaderboard.highscores

	$b1_1st.text = "%.3f" % scores[0][0]
	$b1_2nd.text = "%.3f" % scores[0][1]
	$b1_3rd.text = "%.3f" % scores[0][2]
	
func _process(_delta: float) -> void:
	var boss1_dist: float = $b1_2nd.global_position.distance_to(Character.global_position)
	var b1_alpha: float = remap(boss1_dist, 0, 40, 1.0, 0.0)
	b1_alpha = clampf(b1_alpha, 0.0, 1.0)
	print(b1_alpha)
	$b1_1st.modulate.a = b1_alpha
	$b1_2nd.modulate.a = b1_alpha
	$b1_3rd.modulate.a = b1_alpha
	$b1_1st.outline_modulate.a = b1_alpha
	$b1_2nd.outline_modulate.a = b1_alpha
	$b1_3rd.outline_modulate.a = b1_alpha
	#BestTimes.text = "%s %.3f %.3f %.3f" % ["Time:", scores[0][0], scores[0][1], scores[0][2]]
	#BestTimes2.text = "%s %.3f %.3f %.3f" % ["Time:", scores[1][0], scores[1][1], scores[1][2]]

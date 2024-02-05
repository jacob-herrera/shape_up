extends Node3D

var dif: int

func _ready():
	dif = SceneManager.difficulty
	
	var scores = Leaderboard.highscores

	

	$b1_1st.text = "%.3f" % scores[dif][0][0]
	$b1_2nd.text = "%.3f" % scores[dif][0][1]
	$b1_3rd.text = "%.3f" % scores[dif][0][2]
	
	$b2_1st.text = "%.3f" % scores[dif][1][0]
	$b2_2nd.text = "%.3f" % scores[dif][1][1]
	$b2_3rd.text = "%.3f" % scores[dif][1][2]
	
func _process(_delta: float) -> void:
	var boss1_dist: float = $b1_2nd.global_position.distance_to(Character.global_position)
	var b1_alpha: float = remap(boss1_dist, 0, 40, 1.0, 0.0)
	b1_alpha = clampf(b1_alpha, 0.0, 1.0)

	$b1_1st.modulate.a = b1_alpha
	$b1_2nd.modulate.a = b1_alpha
	$b1_3rd.modulate.a = b1_alpha
	$b1_1st.outline_modulate.a = b1_alpha
	$b1_2nd.outline_modulate.a = b1_alpha
	$b1_3rd.outline_modulate.a = b1_alpha

	var boss2_dist: float = $b2_2nd.global_position.distance_to(Character.global_position)
	var b2_alpha: float = remap(boss2_dist, 0, 40, 1.0, 0.0)
	b2_alpha = clampf(b2_alpha, 0.0, 1.0)

	$b2_1st.modulate.a = b2_alpha
	$b2_2nd.modulate.a = b2_alpha
	$b2_3rd.modulate.a = b2_alpha
	$b2_1st.outline_modulate.a = b2_alpha
	$b2_2nd.outline_modulate.a = b2_alpha
	$b2_3rd.outline_modulate.a = b2_alpha

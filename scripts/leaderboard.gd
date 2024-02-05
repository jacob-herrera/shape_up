extends Node

var highscores = [[0,0,0], [0,0,0]]

func check_high_score(boss : int, time : float):
	for score in 3:
		if time >= highscores[boss][score]:
			highscores[boss][score] = time
			return

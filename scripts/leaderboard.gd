extends Node

var highscores = [[0,0,0], [0,0,0]]

func check_high_score(boss : int, time : float):
	print("run")
	for score in 3:
		if time >= highscores[boss][score]:
			highscores[boss].insert(score, time)
			highscores[boss].pop_back()
			return

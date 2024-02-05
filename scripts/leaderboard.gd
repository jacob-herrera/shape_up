extends Node

var highscores = [[[0,0,0],[0,0,0]],[[0,0,0],[0,0,0]],[[0,0,0],[0,0,0]]]

func check_high_score(difficulty: int, boss : int, time : float):
	for score in 3:
		if time >= highscores[difficulty][boss][score]:
			highscores[difficulty][boss].insert(score, time)
			highscores[difficulty][boss].pop_back()
			break
	SaveData.save_config()

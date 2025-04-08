extends Node

var score := 0
var score_label: Label = null

func reset_score():
	score = 0 

func add_score(value: int):
	score += value
	_update_ui()

func _update_ui():
	if score_label:
		score_label.text = "Score : %d" % score

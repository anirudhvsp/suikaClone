extends Control

@onready var score_label: Label = $Score

func _ready():
	ScoreManager.score_label = score_label

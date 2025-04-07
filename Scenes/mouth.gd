extends Node2D

@onready var sprite_list: Array[Sprite2D] = [
	$flat,
	$smile,
	$smitle2,
	$frown
]

var time_accumulator: float = 0.0
var next_switch_time: float = randf_range(2.0, 3.0)

func _ready() -> void:
	randomize()
	_show_random_sprite()

func _process(delta: float) -> void:
	time_accumulator += delta
	if time_accumulator >= next_switch_time:
		_show_random_sprite()
		time_accumulator = 0.0
		next_switch_time = randf_range(2.0, 3.0)

func _show_random_sprite() -> void:
	# Hide all first
	for sprite in sprite_list:
		sprite.visible = false
	# Pick one to show
	var random_index = randi() % sprite_list.size()
	sprite_list[random_index].visible = true

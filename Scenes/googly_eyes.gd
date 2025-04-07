extends Node2D

@export var eyeball_move_radius: float = 15.0  # how far the pupil can move from center

@onready var eyeball:    Sprite2D = $eyeball3
@onready var eyeball_2:  Sprite2D = $eyeball2

var _default_pos1: Vector2
var _default_pos2: Vector2

func _ready() -> void:
	# store the “center” positions so we can offset from them each frame
	_default_pos1 = eyeball.position
	_default_pos2 = eyeball_2.position

func _process(delta: float) -> void:
	# get the pointer (mouse or last touch) in this node’s local space
	var global_pos = get_viewport().get_mouse_position()
	var local_pos  = to_local(global_pos)

	_update_eye(eyeball,   _default_pos1, local_pos)
	_update_eye(eyeball_2, _default_pos2, local_pos)

func _update_eye(eye: Sprite2D, center: Vector2, target: Vector2) -> void:
	var offset = target - center
	var dist   = offset.length()
	if dist > eyeball_move_radius:
		offset = offset.normalized() * eyeball_move_radius
	eye.position = center + offset

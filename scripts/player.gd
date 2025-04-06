extends Node2D
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var fruit_scene: PackedScene
var dragging := false

func _ready() -> void:
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) \
	or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		dragging = true
		queue_redraw()  # start drawing immediately

	if (event is InputEventScreenTouch and not event.pressed) \
	or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		if dragging:
			dragging = false
			drop_fruit()
			queue_redraw()  # clear the line

func _process(delta: float) -> void:
	if dragging:
		var p = get_viewport().get_mouse_position()
		global_position.x = clamp(p.x, 0, get_viewport_rect().size.x)
	queue_redraw()  # keep the line in sync with movement

func _draw() -> void:
	if not dragging:
		return

	var dash_len = 12
	var gap = 6
	var col = Color(0, 0, 0, 0.6)
	var thickness = 2

	var total = get_viewport_rect().size.y - global_position.y
	var y = 0.0
	while y < total:
		var y2 = min(y + dash_len, total)
		draw_line(Vector2(0, y), Vector2(0, y2), col, thickness)
		y += dash_len + gap

func drop_fruit() -> void:
	if fruit_scene:
		var fruit = fruit_scene.instantiate()
		fruit.global_position = global_position
		get_parent().add_child(fruit)

		# Create a squash & stretch animation using Tween
		var tween = create_tween()
		sprite_2d.scale = Vector2.ONE * 0.6  # start smaller
		tween.tween_property(sprite_2d, "scale", Vector2.ONE * 1.2, 0.1)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite_2d, "scale", Vector2.ONE, 0.1)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

extends Node2D
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var fruit_scene: PackedScene
var dragging := false
var last_drop_time := 0.0
const DROP_COOLDOWN := 0.5  # seconds
var initialScale = Vector2(1.78,2.669)


func _ready() -> void:
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) \
	or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		dragging = true
		queue_redraw()

	if (event is InputEventScreenTouch and not event.pressed) \
	or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		if dragging:
			dragging = false
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_drop_time >= DROP_COOLDOWN:
				last_drop_time = current_time
				drop_fruit()
			queue_redraw()

func _process(delta: float) -> void:
	if dragging:
		var p = get_viewport().get_mouse_position()
		global_position.x = clamp(p.x, 0, get_viewport_rect().size.x)
	queue_redraw()

func _draw() -> void:
	if not dragging:
		return

	var dash_len = 12
	var gap = 6
	var col = Color(0, 0, 0, 0.6)
	var thickness = 2
	var total = get_viewport_rect().size.y - global_position.y
	var y = 0.0
	# Drawing line code can be uncommented when needed

func drop_fruit() -> void:
	if fruit_scene:
		var fruit = fruit_scene.instantiate()
		fruit.global_position = global_position
		get_parent().add_child(fruit)

		if fruit is RigidBody2D:
			var random_spin = randf_range(-5.0, 5.0)
			fruit.angular_velocity = random_spin

		var tween = create_tween()
		sprite_2d.scale = initialScale * 0.6
		tween.tween_property(sprite_2d, "scale", initialScale * 1.2, 0.1)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite_2d, "scale", initialScale, 0.1)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

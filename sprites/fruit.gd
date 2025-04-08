extends RigidBody2D
class_name Fruit

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var poof_scene: PackedScene

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var center_colors := {}
var merging := false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1

	# Make the shape unique
	collision_shape_2d.shape = collision_shape_2d.shape.duplicate()

	# Choose random initial frame
	var chosen_frame = _choose_random_frame()
	animated_sprite_2d.frame = chosen_frame

	# Set radius based on chosen frame: 40 + (frame * 10)
	var circle = collision_shape_2d.shape as CircleShape2D
	circle.radius = 40 + chosen_frame * 10

	body_entered.connect(_on_body_entered)
	_cache_center_colors()

func _choose_random_frame() -> int:
	var weights = [50.00, 14.29, 11.90, 9.52, 7.14, 4.76, 2.38, 0.00];
	var total = 0.0
	for w in weights:
		total += w
	var rand = randf() * total
	var cumulative = 0.0
	for i in weights.size():
		cumulative += weights[i]
		if rand < cumulative:
			return i
	return 0  # fallback

func _cache_center_colors() -> void:
	var sf = animated_sprite_2d.sprite_frames
	var anim = animated_sprite_2d.animation
	if not sf.has_animation(anim):
		push_error("Fruit has no animation '%s'!" % anim)
		return

	var fc = sf.get_frame_count(anim)
	for i in range(fc):
		var tex = sf.get_frame_texture(anim, i)
		center_colors[i] = _sample_texture_center(tex)

func _sample_texture_center(tex: Texture2D) -> Color:
	if tex is AtlasTexture:
		var at = tex as AtlasTexture
		var atlas_tex = at.atlas
		var img: Image
		if atlas_tex is ImageTexture:
			img = (atlas_tex as ImageTexture).get_data()
		else:
			img = atlas_tex.get_image()
		var region = at.region
		var cx = int(region.position.x + region.size.x * 0.5)
		var cy = int(region.position.y + region.size.y * 0.5)
		return img.get_pixel(cx, cy)

	elif tex is ImageTexture:
		var img = tex.get_data()
		return img.get_pixel(img.get_width() / 2, img.get_height() / 2)

	else:
		var img = tex.get_image()
		return img.get_pixel(img.get_width() / 2, img.get_height() / 2)

func _on_body_entered(body: Node) -> void:
	if merging:
		return
	if body is Fruit and body.animated_sprite_2d.frame == animated_sprite_2d.frame:
		merging = true
		_start_merge_animation(body)

func _start_merge_animation(other: Fruit) -> void:
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	other.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

	other.contact_monitor = false

	var midpoint := (global_position + other.global_position) / 2.0

	var t1 = create_tween()
	t1.tween_property(self, "global_position", midpoint, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var t2 = create_tween()
	t2.tween_property(other, "global_position", midpoint, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	t2.finished.connect(Callable(self, "_finish_merge").bind(other))

func _finish_merge(other: Fruit) -> void:
	other.queue_free()

	var anim = animated_sprite_2d.animation
	var fc = animated_sprite_2d.sprite_frames.get_frame_count(anim)
	animated_sprite_2d.frame = min(animated_sprite_2d.frame + 1, fc - 1)

	var circle = collision_shape_2d.shape as CircleShape2D
	circle.radius += 10

	if poof_scene:
		var poof = poof_scene.instantiate()
		poof.global_position = global_position
		var c = center_colors[animated_sprite_2d.frame]
		poof.modulate = c
		get_parent().add_child(poof)

	if audio_stream_player_2d and not audio_stream_player_2d.playing:
		audio_stream_player_2d.play()

	Input.vibrate_handheld(500)
	freeze = false
	merging = false

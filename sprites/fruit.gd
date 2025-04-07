extends RigidBody2D
class_name Fruit
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var poof_scene: PackedScene   # your poof/particle effect here

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
var center_colors := {}
var merging := false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	# make this fruit’s collision shape unique
	collision_shape_2d.shape = collision_shape_2d.shape.duplicate()
	body_entered.connect(_on_body_entered)
	_cache_center_colors()

func _cache_center_colors() -> void:
	var sf   = animated_sprite_2d.sprite_frames
	var anim = animated_sprite_2d.animation
	if not sf.has_animation(anim):
		push_error("Fruit has no animation '%s'!" % anim)
		return

	var fc = sf.get_frame_count(anim)
	for i in range(fc):
		var tex = sf.get_frame_texture(anim, i)
		center_colors[i] = _sample_texture_center(tex)
		
		
func _sample_texture_center(tex: Texture2D) -> Color:
	# handle AtlasTexture by sampling its atlas + region
	if tex is AtlasTexture:
		var at = tex as AtlasTexture
		var atlas_tex = at.atlas
		# atlas must be an ImageTexture or Texture2D with get_image()
		var img: Image
		if atlas_tex is ImageTexture:
			img = (atlas_tex as ImageTexture).get_data()
		else:
			img = atlas_tex.get_image()
		var region = at.region
		var cx = int(region.position.x + region.size.x * 0.5)
		var cy = int(region.position.y + region.size.y * 0.5)
		var col = img.get_pixel(cx, cy)
		return col

	# plain ImageTexture
	elif tex is ImageTexture:
		var img = (tex as ImageTexture).get_data()
		var col = img.get_pixel(img.get_width() / 2, img.get_height() / 2)
		return col

	# fallback: any Texture2D
	else:
		var img = tex.get_image()
		var col = img.get_pixel(img.get_width() / 2, img.get_height() / 2)
		return col
		
		
func _on_body_entered(body: Node) -> void:
	if merging:
		return
	if body is Fruit and body.animated_sprite_2d.frame == animated_sprite_2d.frame:
		merging = true
		_start_merge_animation(body)

func _start_merge_animation(other: Fruit) -> void:
	# 1) switch *both* bodies into a kinematic‑style freeze
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	other.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

	freeze = true
	other.freeze = true
	other.contact_monitor = false  # prevent new merges while tweening

	var midpoint := (global_position + other.global_position) / 2.0

	# Tween both fruits to the midpoint
	var t1 = create_tween()
	t1.tween_property(self, "global_position", midpoint, 0.3)\
	   .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var t2 = create_tween()
	t2.tween_property(other, "global_position", midpoint, 0.2)\
	   .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Call _finish_merge once both tweens finish
	t2.finished.connect(Callable(self, "_finish_merge").bind(other))

func _finish_merge(other: Fruit) -> void:
	# clean up the other fruit
	other.queue_free()

	# bump to the next sprite‐frame
	var anim = animated_sprite_2d.animation
	var fc = animated_sprite_2d.sprite_frames.get_frame_count(anim)
	animated_sprite_2d.frame = min(animated_sprite_2d.frame + 1, fc - 1)

	# grow *this* fruit’s collision circle by 10px
	var circle = collision_shape_2d.shape as CircleShape2D
	circle.radius += 10

	# play a poof effect
	if poof_scene:
		var poof = poof_scene.instantiate()
		poof.global_position = global_position
		var c = center_colors[ animated_sprite_2d.frame ]
		poof.modulate = c
		get_parent().add_child(poof)
	if audio_stream_player_2d and not audio_stream_player_2d.playing:
		audio_stream_player_2d.play()
	# 4) unfreeze *this* fruit so physics resumes
	freeze = false
	merging = false

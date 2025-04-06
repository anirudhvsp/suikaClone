extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# (Optional) ensure this animation won’t loop,
	# if you haven’t already disabled looping in the SpriteFrames resource:
	animated_sprite_2d.sprite_frames.set_animation_loop(
		animated_sprite_2d.animation, false
	)

	# Start the poof animation
	animated_sprite_2d.play()

	# When it finishes, call our handler
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()

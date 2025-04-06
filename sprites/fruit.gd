extends RigidBody2D
class_name Fruit

@export var poof_scene: PackedScene   # your poof/particle effect here

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var merging := false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	# make this fruit’s collision shape unique
	collision_shape_2d.shape = collision_shape_2d.shape.duplicate()
	body_entered.connect(_on_body_entered)

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

	# 2) tween the other fruit into this one
	var t = create_tween()
	t.tween_property(other, "global_position", global_position, 0.3)\
	 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 3) when it finishes, call _finish_merge(other)
	var cb = Callable(self, "_finish_merge").bind(other)
	t.finished.connect(cb)

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
		get_parent().add_child(poof)

	# 4) unfreeze *this* fruit so physics resumes
	freeze = false
	merging = false

# PoofParticles2D.gd
extends CPUParticles2D


func _ready() -> void:
	# ensure it’s one-shot
	one_shot = true
	emitting = true
	# queue_free after its lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

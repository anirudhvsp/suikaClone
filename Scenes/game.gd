extends Node2D

# how much tilt (0–1) you need before gravity starts to shift
@export var tilt_threshold: float = 0.2

# the maximum gravity strength (pixels/s²).  
# By default Godot’s is 98 (world units), but you can pull from ProjectSettings:
@export var max_gravity_strength: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Set the default gravity direction to Vector2(0, 1) (downwards)
	ProjectSettings.set_setting("physics/2d/default_gravity_vector", Vector2(0, 1))
	# Set the default gravity strength to 980
	ProjectSettings.set_setting("physics/2d/default_gravity", 980)

func _physics_process(delta: float) -> void:
	# read the device accelerometer (x = left/right, y = forward/back)
	var accel : Vector3 = Input.get_accelerometer()
	var tilt := Vector2(accel.x, -accel.y)
	var mag := tilt.length()
	var space := get_viewport().find_world_2d().space
	if mag > tilt_threshold:
		var norm: float = clamp(
			(mag - tilt_threshold) / (1.0 - tilt_threshold),
			0.0,
			1.0
		)
		# set the global gravity *direction*
		PhysicsServer2D.area_set_param(
			space,
			PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR,
			tilt.normalized()
		)
		# set the global gravity *strength*
		PhysicsServer2D.area_set_param(
			space,
			PhysicsServer2D.AREA_PARAM_GRAVITY,
			max_gravity_strength * norm
		)
	else:
		# restore straight‑down, full‑strength gravity
		PhysicsServer2D.area_set_param(
			space,
			PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR,
			Vector2.DOWN
		)
		PhysicsServer2D.area_set_param(
			space,
			PhysicsServer2D.AREA_PARAM_GRAVITY,
			max_gravity_strength
		)

extends Node2D

# how much tilt (0–1) you need before gravity starts to shift
@export var tilt_threshold: float = 0.2
@onready var fillup_area: Area2D = $fillupArea
@onready var game_over_line: Sprite2D = $line
var fruit_states = {} 
# the maximum gravity strength (pixels/s²).  
# By default Godot’s is 98 (world units), but you can pull from ProjectSettings:
@export var max_gravity_strength: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var fruit_static_timer = {}  # Stores how long a fruit has been static above the red line

const GAME_OVER_DELAY = 2.0  # Time (in seconds) before triggering game over if fruit is static
@onready var game_over: Node2D = $GameOver
@onready var background_2: Sprite2D = $background2

func _on_fillup_area_body_entered(body):
	# Only consider RigidBody2D fruits. Optionally, check if they are in a specific group.
	if not (body is RigidBody2D):
		return
	
	# If this is the first time, mark it as "entered" (from above)
	if not fruit_states.has(body):
		fruit_states[body] = "entered"
	else:
		game_over_line.visible=true
		# If the fruit had already been marked as exited from the bottom,
		# then it has come back from below—this is our condition to trigger game over.

func _on_fillup_area_body_exited(body):
	# Only consider RigidBody2D fruits.
	if not (body is RigidBody2D):
		return
	
	# Depending on the fruit's exit position, update its state.
	# Here we assume fillup_area.global_position.y marks the threshold.
	# If the fruit's y is greater than the fill area (i.e. lower on the screen), consider it exiting from the bottom.
	if body.global_position.y > fillup_area.global_position.y:
		fruit_states[body] = "exited_from_bottom"
	else:
		fruit_states[body] = "exited_from_top"



func _ready():
	# Set the default gravity direction to Vector2(0, 1) (downwards)
	ProjectSettings.set_setting("physics/2d/default_gravity_vector", Vector2(0, 1))
	# Set the default gravity strength to 980
	ProjectSettings.set_setting("physics/2d/default_gravity", 980)
	fillup_area.body_entered.connect(_on_fillup_area_body_entered)
	fillup_area.body_exited.connect(_on_fillup_area_body_exited)

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
	for body in fruit_states.keys():
		if not is_instance_valid(body):
			continue

		var above_line = body.global_position.y < game_over_line.global_position.y
		var is_static = body.linear_velocity.length() < 5.0  # Threshold for "not moving"

		if above_line and is_static:
			if not fruit_static_timer.has(body):
				fruit_static_timer[body] = 0.0
			fruit_static_timer[body] += delta

			if fruit_static_timer[body] > GAME_OVER_DELAY:
				game_over.visible=true
				background_2.visible=true
				game_over_line.visible = true  # Optional visual signal
				get_tree().paused = true
				await get_tree().create_timer(3).timeout
				get_tree().reload_scene() 
				
				# You can add more game-over handling logic here
		else:
			fruit_static_timer[body] = 0.0  # Reset timer if fruit moves or drops below

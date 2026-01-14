extends VehicleBody3D

const STEER_SPEED = 1.5
const STEER_LIMIT = 0.4
const BRAKE_STRENGTH = 2.0

@export var engine_force_value := 40.0

var previous_speed := linear_velocity.length()
var _steer_target := 0.0

#@onready var desired_engine_pitch: float = $EngineSound.pitch_scale

#func _physics_process(delta: float):


func handle_input(delta: float) -> void:
	_steer_target = Input.get_axis(&"vehicle_right", &"vehicle_left")
	_steer_target *= STEER_LIMIT

	if abs(linear_velocity.length() - previous_speed) > 1.0:
		Input.vibrate_handheld(100)
		for joypad in Input.get_connected_joypads():
			Input.start_joy_vibration(joypad, 0.0, 0.5, 0.1)

	# Automatically accelerate when using touch or holding forward.
	if DisplayServer.is_touchscreen_available() or Input.is_action_pressed(&"vehicle_forward"):
		var speed := linear_velocity.length()
		if speed < 5.0 and not is_zero_approx(speed):
			engine_force = clampf(engine_force_value * 5.0 / speed, 0.0, 100.0)
		else:
			engine_force = engine_force_value

		if not DisplayServer.is_touchscreen_available():
			engine_force *= Input.get_action_strength(&"vehicle_forward")
	else:
		engine_force = 0.0

	# Handle reverse input
	if Input.is_action_pressed(&"vehicle_back"):
		var speed := linear_velocity.length()
		if speed < 5.0 and not is_zero_approx(speed):
			engine_force = -clampf(engine_force_value * BRAKE_STRENGTH * 5.0 / speed, 0.0, 100.0)
		else:
			engine_force = -engine_force_value * BRAKE_STRENGTH

		engine_force *= Input.get_action_strength(&"vehicle_back")

	# Smooth steering
	steering = move_toward(steering, _steer_target, STEER_SPEED * delta)

	# Save current speed for impact detection
	previous_speed = linear_velocity.length()

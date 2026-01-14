extends Camera3D

@export var height := 1.5
@export var distance := 8.0
@export var lerpFactor := 0.125
@export var target: Node
@export var orbitSpeed := Vector2(0.005, 0.005) # x = yaw speed, y = pitch speed
@export var vehicles: Array[Node]

var vehicleUI
var vehicleIdx := 0

# Manual orbit angles
var yaw := 0.0 # left/right
var pitch := 0.0 # up/down

# Pitch limits to avoid flipping
const MIN_PITCH := deg_to_rad(-80)
const MAX_PITCH := deg_to_rad(80)

func _ready():
	if target:
		look_at(target.global_position)

func unhandled_input_camera(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw -= event.relative.x * orbitSpeed.x
		pitch -= event.relative.y * orbitSpeed.y
		pitch = clamp(pitch, MIN_PITCH, MAX_PITCH)

func physics_process_camera():
	if not target:
		return

	# Compute rotation relative to target orientation
	var rotation_vehicle = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)

	# Apply offset from target's local space
	var offset_local = rotation_vehicle * Vector3(0, height, distance)

	# Transform to world space using the target’s rotation
	var offset_world = target.global_transform.basis * offset_local

	var target_position = target.global_position
	var desired_position = target_position + offset_world

	# Smooth movement
	global_position = global_position.lerp(desired_position, lerpFactor)

	# Always look at the target
	look_at(target_position)
	
	
	#ADD SPRINARM AS THE PARENT CHANGE THIS SCRIPT TO ATTACH TO THE SRPING ARM INSTEAD, MAKE COLLISION MASK AND CHANGE INCLUDE OF THE CAMERA TO THE MULTIPLE SCRIPTS

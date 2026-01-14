extends Node3D

@onready var body: VehicleBody3D = $Body
var spawn_position: Vector3
var spawn_rotation: Basis

func _ready():
	# Save the initial transform (set in the editor) as the spawn point
	spawn_position = body.global_transform.origin
	spawn_rotation = body.global_transform.basis

func handle_input(delta: float) -> void:
	if Input.is_action_pressed("respawn_car"):
		respawn()
	
	body.handle_input(delta)

func respawn():
	# Reset position and rotation
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.global_transform = Transform3D(spawn_rotation, spawn_position)

func set_respawn(spawn_location: Transform3D) -> void:
	spawn_position = spawn_location.origin
	spawn_rotation = spawn_location.basis

extends CharacterBody3D

@export var mouse_sensitivity := 0.002
@export var move_speed := 5.0
@export var gravity := 9.8
@export var jump_height := 1.0
@export var fall_multiplier: float = 2.5

@export var terrain_node: Node3D
@export var new_car_controller: Node3D
@export var object_placer: Node3D
@export var march_terrain_node: Node3D
@export var mode_manager: Node3D

@onready var camera_pivot: Node3D = %CameraPivot
@onready var smooth_camera: Camera3D = %SmoothCamera
@onready var ray_cast_terrain: RayCast3D = $CameraPivot/RayCastTerrain
@onready var debug_shovel: CSGBox3D = $CameraPivot/DebugShovel

@onready var center_container: CenterContainer = $CenterContainer

var monster_truck: KVVehicle = null
var camera_monster_truck: Camera3D = null

var mouse_motion := Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	debug_shovel.hide()
	mode_manager.set_mode(mode_manager.PlayerMode.NORMAL)
	mode_manager.ray_cast_terrain = ray_cast_terrain
	mode_manager.terrain_node = terrain_node
	mode_manager.object_placer = object_placer
	mode_manager.march_terrain_node = march_terrain_node

func _physics_process(delta: float) -> void:
	if not mode_manager.is_in_mode(mode_manager.PlayerMode.DRIVING):
		handle_camera_rotation()

		# Handle movement input
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if direction:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)

		if mode_manager.is_in_mode(mode_manager.PlayerMode.EDITOR) or mode_manager.is_in_mode(mode_manager.PlayerMode.OBJECT_PLACER):
			# Flying: use jump and crouch to move vertically
			if Input.is_action_pressed("jump"):
				velocity.y = move_speed
			elif Input.is_action_pressed("crouch"):
				velocity.y = -move_speed
			else:
				velocity.y = 0.0
		elif mode_manager.is_in_mode(mode_manager.PlayerMode.NORMAL):
			# Normal gravity
			if not is_on_floor():
				if velocity.y >= 0:
					velocity.y -= gravity * delta
				else:
					velocity.y -= gravity * delta * fall_multiplier
			else:
				if Input.is_action_just_pressed("jump"):
					velocity.y = sqrt(jump_height * 2.0 * gravity)

		# Apply movement
		move_and_slide()
		
	if mode_manager.is_in_mode(mode_manager.PlayerMode.OBJECT_PLACER):
		if object_placer.has_method("process_placer"):
			object_placer.process_placer()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mode_normal"):
		debug_shovel.hide()
		mode_manager.set_mode(mode_manager.PlayerMode.NORMAL)
		switch_camera(false)
		center_container.show()
	elif event.is_action_pressed("mode_editor"):
		debug_shovel.show()
		mode_manager.set_mode(mode_manager.PlayerMode.EDITOR)
		#switch_camera(false)
		center_container.show()
	elif event.is_action_pressed("mode_object_placer"):
		debug_shovel.hide()
		mode_manager.set_mode(mode_manager.PlayerMode.OBJECT_PLACER)
		#switch_camera(false)
		if object_placer.has_method("create_preview"):
			object_placer.create_preview()
		center_container.show()
		
	if mode_manager.is_in_mode(mode_manager.PlayerMode.EDITOR):
		mode_manager.handle_editor_input(event)
	elif mode_manager.is_in_mode(mode_manager.PlayerMode.OBJECT_PLACER):
		mode_manager.handle_object_placer_input(event)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			mouse_motion = -event.relative * mouse_sensitivity
		
		
func handle_camera_rotation() -> void:
	rotate_y(mouse_motion.x)
	camera_pivot.rotate_x(mouse_motion.y)
	camera_pivot.rotation_degrees.x = clampf(
		camera_pivot.rotation_degrees.x, -90.0, 90.0
	)
	mouse_motion = Vector2.ZERO
	
func switch_camera(to_vehicle: bool) -> void:
	if to_vehicle:
		if smooth_camera:
			smooth_camera.current = false
		if camera_monster_truck:
			camera_monster_truck.current = true
		#vehicle_camera.current = true
	else:
		#vehicle_camera.current = false
		if camera_monster_truck:
			camera_monster_truck.current = false
		if smooth_camera:
			smooth_camera.current = true

func set_vehicle(vehicle: Node):
	monster_truck = vehicle
	camera_monster_truck = vehicle.get_node_or_null("Camera3D")
	if camera_monster_truck:
		camera_monster_truck.current = true
	else:
		printerr("Camera3D not found in vehicle.")

func set_player_enabled(enabled: bool):
	visible = enabled
	set_process(enabled)
	set_physics_process(enabled)
	$CollisionShape3D.disabled = not enabled

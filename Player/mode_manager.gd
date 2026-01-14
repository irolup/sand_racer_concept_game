extends Node3D

@export var player: CharacterBody3D

# Enum for player modes
enum PlayerMode { NORMAL, EDITOR, DRIVING, OBJECT_PLACER }

var ray_cast_terrain: RayCast3D
var terrain_node
var object_placer
var march_terrain_node

# Current mode of the player
var current_mode := PlayerMode.NORMAL
var previous_mode := PlayerMode.NORMAL

signal mode_changed(previous_mode, new_mode)

func _ready():
	match GameState.current_mode:
		GameState.GameMode.NORMAL:
			set_mode(PlayerMode.NORMAL)
		GameState.GameMode.EDITOR:
			set_mode(PlayerMode.EDITOR)
		GameState.GameMode.DRIVING:
			set_mode(PlayerMode.DRIVING)
		GameState.GameMode.OBJECT_PLACER:
			set_mode(PlayerMode.OBJECT_PLACER)

# Function to switch modes
func set_mode(mode: PlayerMode) -> void:
	# Don't emit signal if mode is already the same (prevents recursion)
	if current_mode == mode:
		return
	
	if current_mode == PlayerMode.OBJECT_PLACER and mode != PlayerMode.OBJECT_PLACER:
		if object_placer and object_placer.has_method("remove_preview"):
			object_placer.remove_preview()

	previous_mode = current_mode
	current_mode = mode
	
	emit_signal("mode_changed", previous_mode, current_mode)

# Function to get the current mode
func get_mode() -> PlayerMode:
	return current_mode

# Function to check if the player is in a specific mode
func is_in_mode(mode: PlayerMode) -> bool:
	return current_mode == mode

func handle_editor_input(event: InputEvent) -> void:
	if not is_in_mode(PlayerMode.EDITOR):
		return
	if event.is_action_pressed("cycle_brush_type"):
		march_terrain_node.cycle_brush_type()
		
		# --- Brush Shape Cycling ---
	if event.is_action_pressed("cycle_up_brush_shape"):
		var new_shape = int(march_terrain_node.current_brush_shape) + 1
		if new_shape >= march_terrain_node.BrushShape.size():
			new_shape = 0
		march_terrain_node.current_brush_shape = march_terrain_node.BrushShape.values()[new_shape]
		var shape_name = march_terrain_node.BrushShape.keys()[new_shape]
		print("Current brush shape: ", shape_name)

	if event.is_action_pressed("cycle_down_brush_shape"):
		var new_shape = int(march_terrain_node.current_brush_shape) - 1
		if new_shape < 0:
			new_shape = march_terrain_node.BrushShape.size() - 1
		march_terrain_node.current_brush_shape = march_terrain_node.BrushShape.values()[new_shape]
		var shape_name = march_terrain_node.BrushShape.keys()[new_shape]
		print("Current brush shape: ", shape_name)
		
		# --- Brush Radius Adjustment ---
	if event.is_action_pressed("increase_brush_radius"):
		march_terrain_node.brush_radius = clamp(march_terrain_node.brush_radius + 0.5, 1.0, 15.0)
		print("Brush radius increased to: ", march_terrain_node.brush_radius)

	if event.is_action_pressed("decrease_brush_radius"):
		march_terrain_node.brush_radius = clamp(march_terrain_node.brush_radius - 0.5, 1.0, 15.0)
		print("Brush radius decreased to: ", march_terrain_node.brush_radius)

	if event is InputEventMouseButton and event.pressed:
			var hit_pos = get_mouse_world_hit()
			if hit_pos != Vector3.ZERO:
				march_terrain_node.apply_brush(hit_pos)
				
					

func handle_object_placer_input(event: InputEvent) -> void:
	if not is_in_mode(PlayerMode.OBJECT_PLACER):
		return
	object_placer.handle_input(event)

func get_mouse_world_hit() -> Vector3:
	var viewport := get_viewport()
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector3.ZERO

	var mouse_pos = viewport.get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10.0  # Ray length (adjust if needed)

	var space_state := get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	return Vector3.ZERO

extends Node3D

@export var object_scenes: Array[PackedScene]
@export var preview_material: Material
@export var player: CharacterBody3D
@export var highlight_material: Material

@onready var ray_cast_terrain: RayCast3D = player.get_node("CameraPivot/RayCastTerrain")

var current_index := 0
var preview_instance: Node3D
var selected_preview_instance: Node3D = null
var current_object_scene: PackedScene
var current_rotation_degrees := 0.0
var current_scale := Vector3.ONE
var selected_object: Node3D = null
var original_material: Material = null
var checkpoint_id_counter := 0

func _ready():
	current_object_scene = object_scenes[current_index]
	create_preview()

func create_preview():
	if preview_instance:
		preview_instance.queue_free()

	# Instance the scene
	preview_instance = current_object_scene.instantiate()
	preview_instance.name = "PreviewObject"

	# Disable collision in preview
	var collision_shape = preview_instance.get_node_or_null("StaticBody3D/CollisionShape3D")
	if collision_shape:
		collision_shape.disabled = true  # <--- disables the collision

	# Optionally override the material for visual feedback
	var mesh = preview_instance.get_node_or_null("StaticBody3D/MeshInstance3D")
	if mesh:
		mesh.material_override = preview_material

	preview_instance.set_physics_process(false)
	add_child(preview_instance)
	

		
func process_placer():
	if not is_instance_valid(preview_instance) and not is_instance_valid(selected_preview_instance):
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

	if result:
		var snapped_position = result.position.snapped(Vector3(1, 1, 1))
		if selected_object and selected_preview_instance:
			selected_preview_instance.global_transform.origin = snapped_position
			selected_preview_instance.visible = true
			if preview_instance:
				preview_instance.visible = false
		elif preview_instance:
			preview_instance.global_transform.origin = snapped_position
			preview_instance.visible = true
			if selected_preview_instance:
				selected_preview_instance.visible = false
	else:
		if selected_preview_instance:
			selected_preview_instance.visible = false
		if preview_instance:
			preview_instance.visible = false

# External input handler
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("place_object"):
		place_at_cursor()
	elif event.is_action_pressed("cycle_down_object"):
		cycle_object(-1)
	elif event.is_action_pressed("cycle_up_object"):
		cycle_object(1)
	elif event.is_action_pressed("rotate_object"):
		if selected_object:
			rotate_selected()
		else:
			rotate_preview()
	elif event.is_action_pressed("scale_up_object"):
		if selected_object:
			scale_selected_up()
		else:
			scale_preview_up()
	elif event.is_action_pressed("scale_down_object"):
		if selected_object:
			scale_selected_down()
		else:
			scale_preview_down()
	elif event.is_action_pressed("select_object"):
		select_object_at_cursor()
	elif event.is_action_pressed("delete_object"):
		delete_selected_object()

# Create the selected object at given position
func place_object(target_position: Vector3):
	var placed_objects_node = get_node("PlacedObjects")
	if not placed_objects_node:
		push_error("PlacedObjects node not found!")
		return

	# Instantiate to check if it's a finish line
	var temp_instance = current_object_scene.instantiate()
	if temp_instance.is_in_group("finish_lines"):
		for child in placed_objects_node.get_children():
			if child.is_in_group("finish_lines"):
				print("Finish line already exists. Select and move it instead.")
				temp_instance.queue_free()
				return

	# Safe to place
	var placed_object = temp_instance
	placed_object.set_meta("source_scene_path", current_object_scene.resource_path)
	print("Placing object from scene: ", current_object_scene)
	print("Scene resource path: ", current_object_scene.resource_path)
	placed_objects_node.add_child(placed_object)

	# Set transform
	var placed_object_transform = placed_object.global_transform
	placed_object_transform.origin = target_position.snapped(Vector3.ONE)
	placed_object_transform.basis = Basis(Vector3.UP, deg_to_rad(current_rotation_degrees))
	placed_object.global_transform = placed_object_transform
	placed_object.scale = current_scale

	# Connect logic
	var game_manager = get_node("../GameManager")

	if placed_object.is_in_group("checkpoints"):
		print("Placed object is in group 'checkpoints'")
		var area = placed_object.get_node_or_null("Area3D")
		if area:
			var id = "cp_" + str(checkpoint_id_counter)
			checkpoint_id_counter += 1
			area.checkpoint_id = id
			area.set_meta("checkpoint_id", id)
			print("Registering checkpoint with id:", area.checkpoint_id)
			game_manager.register_checkpoint(area)
		else:
			print("Area3D node not found in checkpoint")

	elif placed_object.is_in_group("finish_lines"):
		var area = placed_object.get_node_or_null("Area3D")
		if area:
			if not area.is_connected("car_reached_finish", Callable(game_manager, "_on_finish_line_entered")):
				area.car_reached_finish.connect(Callable(game_manager, "_on_finish_line_entered"))
			game_manager.set_finish_line(area)
		else:
			print("Error: Area3D node not found in finish line object.")
	elif placed_object.is_in_group("starting_lines"):
		print("Placed object is in group 'starting_lines'")
		game_manager.set_starting_line(placed_object)
	

# Remove placed object under cursor
func delete_object_at_cursor():
	if ray_cast_terrain.is_colliding():
		var collider = ray_cast_terrain.get_collider()
		if collider and collider.get_parent().name == "PlacedObjects":
			collider.queue_free()

# Cycle between available objects
func cycle_object(direction: int):
	current_index = (current_index + direction) % object_scenes.size()
	if current_index < 0:
		current_index = object_scenes.size() - 1
	current_object_scene = object_scenes[current_index]
	create_preview()
	
func remove_preview() -> void:
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null
		

func rotate_preview():
	current_rotation_degrees = fmod(current_rotation_degrees + 45.0, 360.0)
	update_preview_transform()

func scale_preview_up():
	current_scale *= 1.1
	update_preview_transform()

func scale_preview_down():
	current_scale *= 0.9
	update_preview_transform()

func update_preview_transform():
	if not preview_instance:
		return

	var origin = preview_instance.global_transform.origin.snapped(Vector3.ONE)
	var  preview_instance_rotation = Basis(Vector3.UP, deg_to_rad(current_rotation_degrees))
	var preview_instance_transform = Transform3D.IDENTITY

	preview_instance_transform.origin = origin
	preview_instance_transform.basis = preview_instance_rotation
	preview_instance.transform = preview_instance_transform
	preview_instance.scale = current_scale
	
func rotate_selected():
	current_rotation_degrees = fmod(current_rotation_degrees + 45.0, 360.0)
	if selected_object:
		var current_rotation_basis = Basis(Vector3.UP, deg_to_rad(current_rotation_degrees))
		selected_object.transform.basis = current_rotation_basis.scaled(current_scale)
	if selected_preview_instance:
		var current_rotation_basis = Basis(Vector3.UP, deg_to_rad(current_rotation_degrees))
		selected_preview_instance.transform.basis = current_rotation_basis.scaled(current_scale)

func scale_selected_up():
	current_scale *= 1.1
	apply_selected_transform()

func scale_selected_down():
	current_scale *= 0.9
	apply_selected_transform()

func apply_selected_transform():
	if selected_object:
		var selected_basis = Basis(Vector3.UP, deg_to_rad(current_rotation_degrees))
		selected_object.transform.basis = selected_basis
		selected_object.scale = current_scale
	if selected_preview_instance:
		var selected_basis = Basis(Vector3.UP, deg_to_rad(current_rotation_degrees))
		selected_preview_instance.transform.basis = selected_basis
		selected_preview_instance.scale = current_scale
	
func select_object_at_cursor():
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state

	# Create a ray query that checks LAYER 1 and LAYER 4 (bit 0 and bit 2)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = (1 << 0) | (1 << 3)

	var result = space_state.intersect_ray(query)
	print(result.collider)

	if result and result.collider and result.collider.get_parent().get_parent().name == "PlacedObjects":
		unselect_current_object()
		
		selected_object = result.collider.get_parent()
		printt("selected", selected_object)

		var mesh = selected_object.get_node_or_null("StaticBody3D/MeshInstance3D")
		if mesh:
			print(mesh)
			# Optional: apply selection highlight

		current_rotation_degrees = selected_object.rotation_degrees.y
		current_scale = selected_object.scale
		create_selected_preview()
	else:
		unselect_current_object()


func unselect_current_object():
	if selected_object:
		var mesh = selected_object.get_node_or_null("StaticBody3D/MeshInstance3D")
		if mesh and original_material:
			mesh.set_surface_override_material(0, original_material)
	selected_object = null
	original_material = null

	if selected_preview_instance:
		selected_preview_instance.queue_free()
		selected_preview_instance = null


func place_at_cursor():
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

	if result:
		if selected_object:
			selected_object.global_transform.origin = result.position.snapped(Vector3(1,1,1))
			if selected_object and selected_object.is_in_group("starting_lines"):
				var game_manager = get_node("../GameManager")
				game_manager.set_starting_line(selected_object)
			unselect_current_object()
		else:
			place_object(result.position.snapped(Vector3(1, 1, 1)))

func create_selected_preview():
	if selected_preview_instance:
		selected_preview_instance.queue_free()

	selected_preview_instance = selected_object.duplicate()
	selected_preview_instance.name = "SelectedPreview"
	selected_preview_instance.set_physics_process(false)

	var collision = selected_preview_instance.get_node_or_null("StaticBody3D/CollisionShape3D")
	if collision:
		collision.disabled = true

	var mesh = selected_preview_instance.get_node_or_null("StaticBody3D/MeshInstance3D")
	if mesh:
		mesh.material_override = preview_material

	add_child(selected_preview_instance)

func delete_selected_object():
	if selected_object:
		var game_manager = get_node("../GameManager")

		if selected_object.is_in_group("checkpoints"):
			var area = selected_object.get_node_or_null("Area3D")
			if area:
				game_manager.unregister_checkpoint(area) 

		elif selected_object.is_in_group("finish_lines"):
			var area = selected_object.get_node_or_null("Area3D")
			if area:
				if area.is_connected("car_reached_finish", Callable(game_manager, "_on_finish_line_entered")):
					area.car_reached_finish.disconnect(Callable(game_manager, "_on_finish_line_entered"))
				game_manager.clear_finish_line() 

		selected_object.queue_free()
		unselect_current_object()

extends Node

# Preload scenes
var main_level_scene = preload("res://Levels/main_level.tscn")
var main_menu_scene = preload("res://Menus/main_menu.tscn")
var editor_menu_scene = preload("res://Menus/editor_loader.tscn")
var user_tracks_menu_scene = preload("res://Menus/user_tracks_menu.tscn")

# Instances
var main_level_instance: Node
var main_menu_instance: Control
var editor_menu_instance: Control
var user_tracks_menu_instance: Control


func _ready():
	# Instantiate everything
	main_level_instance = main_level_scene.instantiate()
	main_menu_instance = main_menu_scene.instantiate()
	editor_menu_instance = editor_menu_scene.instantiate()
	user_tracks_menu_instance = user_tracks_menu_scene.instantiate()

	# Add to tree
	add_child(main_level_instance)
	add_child(main_menu_instance)
	add_child(editor_menu_instance)
	add_child(user_tracks_menu_instance)

	# Disable everything except main menu
	_set_active(main_level_instance, false)
	_set_active(editor_menu_instance, false)
	_set_active(user_tracks_menu_instance, false)
	_set_active(main_menu_instance, true)

	# Pass launcher reference to menus
	main_menu_instance.set_meta("launcher", self)
	editor_menu_instance.set_meta("launcher", self)
	user_tracks_menu_instance.set_meta("launcher", self)


# --- Scene Control ---

func _set_active(node: Node, active: bool) -> void:
	if node == null:
		return
	
	node.visible = active
	
	if node is Control:
		# Enable/disable input for Control nodes
		node.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
		node.set_process_input(active)
		node.set_process_unhandled_input(active)
		node.set_process_unhandled_key_input(active)
	else:
		# Non-Control (like main level) -> just process mode
		node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	
	# Special case: main level mouse
	if node == main_level_instance:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE)


func start_new_map(track_name: String):
	GameState.current_mode = GameState.GameMode.EDITOR
	GameState.track_name = track_name
	initialize_main_level(GameState.GameMode.EDITOR)


func load_existing_map(track_name: String):
	GameState.current_mode = GameState.GameMode.EDITOR
	GameState.track_name = track_name
	initialize_main_level(GameState.GameMode.EDITOR)


func initialize_main_level(start_mode: int = GameState.GameMode.EDITOR):
	# Switch: hide menus, show level
	_set_active(main_menu_instance, false)
	_set_active(editor_menu_instance, false)
	_set_active(user_tracks_menu_instance, false)
	_set_active(main_level_instance, true)

	# Load the map
	var game_manager = main_level_instance.get_node_or_null("GameManager")
	if game_manager:
		game_manager.load_current_track(start_mode)
		#game_manager.start_mode(start_mode)


func back_to_main_menu():
	if main_level_instance:
		var game_manager = main_level_instance.get_node_or_null("GameManager")
		if game_manager:
			# Free the monster truck from game_manager
			if game_manager.monster_truck:
				if is_instance_valid(game_manager.monster_truck):
					game_manager.monster_truck.queue_free()
				game_manager.monster_truck = null

			# Free the monster truck from vehicle_manager
			var vehicle_manager = main_level_instance.get_node_or_null("vehicle_manager")
			if vehicle_manager and vehicle_manager.truck:
				if is_instance_valid(vehicle_manager.truck):
					vehicle_manager.truck.queue_free()
				vehicle_manager.set_truck(null)

			# Free the race HUD / menu
			if game_manager.race_hud:
				if is_instance_valid(game_manager.race_hud):
					game_manager.race_hud.queue_free()
				game_manager.race_hud = null

			# Free the race timer
			if game_manager.race_timer:
				if is_instance_valid(game_manager.race_timer):
					game_manager.race_timer.queue_free()
				game_manager.race_timer = null

			# Clear pending mode to prevent auto-spawn
			game_manager.pending_start_mode = GameState.GameMode.EDITOR

			# Optional: disconnect terrain_ready signals to avoid late triggers
			

	# Switch visible nodes
	_set_active(main_level_instance, false)
	_set_active(editor_menu_instance, false)
	_set_active(user_tracks_menu_instance, false)
	_set_active(main_menu_instance, true)

	# Ensure meta is set on main menu (in case it was lost)
	if main_menu_instance and not main_menu_instance.has_meta("launcher"):
		main_menu_instance.set_meta("launcher", self)

	# Reset game state
	GameState.current_mode = GameState.GameMode.EDITOR
	GameState.came_from_editor = false


func open_editor_menu():
	_set_active(main_menu_instance, false)
	_set_active(editor_menu_instance, true)


func open_user_tracks_menu():
	_set_active(main_menu_instance, false)
	_set_active(user_tracks_menu_instance, true)


func back_from_submenu():
	_set_active(editor_menu_instance, false)
	_set_active(user_tracks_menu_instance, false)
	_set_active(main_menu_instance, true)

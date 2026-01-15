extends Control

signal start_race
signal quit_game
signal retry_race

@onready var race_button = $Panel/VBoxContainer/RaceButton
@onready var retry_button = $Panel/VBoxContainer/RetryButton
@onready var quit_button = $Panel/VBoxContainer/QuitButton
@onready var best_time_label: Label = $Panel/VBoxContainer/Label
@onready var return_button: Button = $Panel/VBoxContainer/ReturnButton

var has_raced_once := false

func _ready():
	visible = true
	race_button.pressed.connect(_on_race_pressed)
	return_button.visible = GameState.came_from_editor
	if GameState.came_from_editor:
		return_button.pressed.connect(_on_return_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	retry_button.visible = false

func set_best_time(seconds: float):
	if seconds > 0:
		best_time_label.text = "Best Time: %.2f s" % seconds
	else:
		best_time_label.text = "No time recorded."

func _on_race_pressed():
	has_raced_once = true
	race_button.visible = false
	retry_button.visible = true
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	emit_signal("start_race")

func _on_retry_pressed():
	print("pressed")
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	print("pressed 1")
	emit_signal("retry_race")

func _on_return_pressed():
	GameState.current_mode = GameState.GameMode.EDITOR
	GameState.came_from_editor = false

	var game_manager = get_parent()
	var player = get_node_or_null("/root/MainLevel/Player")
	
	if game_manager:
		# Ensure pending_start_mode is set to EDITOR to prevent auto-switching
		game_manager.pending_start_mode = GameState.GameMode.EDITOR
		# Clean up race UI resources
		if game_manager.race_hud:
			game_manager.race_hud.queue_free()
			game_manager.race_hud = null
		if game_manager.race_timer:
			game_manager.race_timer.queue_free()
			game_manager.race_timer = null
		
		# Explicitly clean up monster truck BEFORE mode change
		# This ensures it's gone before the mode change handler runs
		if game_manager.monster_truck:
			if is_instance_valid(game_manager.monster_truck):
				# Disable truck camera first
				var truck_camera = game_manager.monster_truck.get_node_or_null("Camera3D")
				if truck_camera:
					truck_camera.current = false
				game_manager.monster_truck.queue_free()
			game_manager.monster_truck = null
		
		if game_manager.vehicle_manager and game_manager.vehicle_manager.truck:
			if is_instance_valid(game_manager.vehicle_manager.truck):
				game_manager.vehicle_manager.truck.queue_free()
			game_manager.vehicle_manager.set_truck(null)

	# Hide menu first and unpause so mode change can process properly
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(false)
	set_process_unhandled_input(false)
	
	get_tree().paused = false
	
	if player and player.mode_manager:
		# Ensure player is visible before mode change (in case it was hidden)
		player.visible = true
		
		player.mode_manager.set_mode(player.mode_manager.PlayerMode.EDITOR)
		if player.has_node("CenterContainer"):
			player.get_node("CenterContainer").show()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_quit_pressed():
	get_tree().paused = false
	emit_signal("quit_game")

func reset():
	has_raced_once = false
	race_button.visible = true
	retry_button.visible = false
	visible = true
	return_button.visible = GameState.came_from_editor
	if GameState.came_from_editor and not return_button.pressed.is_connected(_on_return_pressed):
		return_button.pressed.connect(_on_return_pressed)

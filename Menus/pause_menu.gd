extends Control

@onready var resume_button: Button = $Panel/VBoxContainer/EditorPanel/ResumeButton
@onready var save_button: Button = $Panel/VBoxContainer/EditorPanel/SaveButton
@onready var test_button: Button = $Panel/VBoxContainer/EditorPanel/TestButton
@onready var quit_button: Button = $Panel/VBoxContainer/EditorPanel/QuitButton

@onready var resume_button_race: Button = $Panel/VBoxContainer/RacingPanel/ResumeButton
@onready var restart_button_race: Button = $Panel/VBoxContainer/RacingPanel/RestartButton
@onready var return_button_race: Button = $Panel/VBoxContainer/RacingPanel/ReturnButton
@onready var quit_button_race: Button = $Panel/VBoxContainer/RacingPanel/QuitButton

@onready var editor_panel = $Panel/VBoxContainer/EditorPanel
@onready var racing_panel = $Panel/VBoxContainer/RacingPanel


func _ready():
	visible = false
	resume_button.pressed.connect(resume_game)
	save_button.pressed.connect(save_map)
	test_button.pressed.connect(start_test_race)
	quit_button.pressed.connect(quit_to_menu)

	resume_button_race.pressed.connect(resume_game)
	restart_button_race.pressed.connect(restart_race)
	return_button_race.pressed.connect(return_to_editor)
	quit_button_race.pressed.connect(quit_to_menu)

func show_pause_menu():
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Choose panel
	match GameState.current_mode:
		GameState.GameMode.EDITOR, GameState.GameMode.OBJECT_PLACER:
			editor_panel.visible = true
			racing_panel.visible = false
			var game_manager = get_node_or_null("/root/MainLevel/GameManager")
			if game_manager:
				test_button.disabled = not game_manager.is_track_raceable()
		GameState.GameMode.DRIVING:
			editor_panel.visible = false
			racing_panel.visible = true
			return_button_race.visible = GameState.came_from_editor

func hide_pause_menu():
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		var race_menu = get_node_or_null("/root/MainLevel/GameManager/RaceMenu")
		if race_menu and race_menu.visible:
			return

		print("ESC pressed! Pause menu visible =", visible)
		if visible:
			hide_pause_menu()
		else:
			show_pause_menu()

func save_map():
	var game_manager = get_node_or_null("/root/MainLevel/GameManager")
	if game_manager:
		var path = GameState.track_name
		if path == "":
			path = "user://tracks/test1.json"  # fallback

		# Ensure the directory exists
		var dir = DirAccess.open("user://")
		if dir:
			if not dir.dir_exists("tracks"):
				dir.make_dir("tracks")

		game_manager.save_current_track()
		print("Map saved to ", path)

func start_test_race():
	var game_manager = get_node_or_null("/root/MainLevel/GameManager")
	if game_manager:
		if not game_manager.is_track_raceable():
			print("Track is not raceable!")
			return
		hide_pause_menu()
		#here we call mode_manager from the player
		var mode_manager = get_node_or_null("/root/MainLevel/ModeManager")
		if mode_manager:
			GameState.came_from_editor = true
			GameState.current_mode = GameState.GameMode.DRIVING
			mode_manager.set_mode(mode_manager.PlayerMode.DRIVING)

func resume_game():
	hide_pause_menu()

func restart_race():
	var game_manager = get_node_or_null("/root/MainLevel/GameManager")
	if game_manager:
		game_manager.restart_race()
		visible = false

func quit_to_menu():
	var game_manager = get_node_or_null("/root/MainLevel/GameManager")
	if game_manager:
		if GameState.current_mode == GameState.GameMode.EDITOR or GameState.current_mode == GameState.GameMode.OBJECT_PLACER or GameState.came_from_editor:
			print("Auto-saving before quit...")
			game_manager.save_current_track()
			print("Save completed.")
	
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var launcher = get_node("/root/Launcher")  # or get_meta if passed
	if launcher:
		hide_pause_menu()
		launcher.back_to_main_menu()

func return_to_editor():
	GameState.current_mode = GameState.GameMode.EDITOR
	GameState.came_from_editor = false

	var mode_manager = get_node_or_null("/root/MainLevel/ModeManager")
	if mode_manager:
		mode_manager.set_mode(mode_manager.PlayerMode.EDITOR)

	var game_manager = get_node_or_null("/root/MainLevel/GameManager")
	if game_manager.race_hud:
		game_manager.race_hud.queue_free()
		game_manager.race_hud = null

	hide_pause_menu()

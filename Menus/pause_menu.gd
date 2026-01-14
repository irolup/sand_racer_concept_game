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

func find_game_manager():
	var gm = get_node_or_null("../GameManager")
	if gm:
		return gm
	
	var launcher = get_node_or_null("/root/Launcher")
	if launcher and launcher.has("main_level_instance") and launcher.main_level_instance:
		gm = launcher.main_level_instance.get_node_or_null("GameManager")
		if gm:
			return gm
	
	gm = get_node_or_null("/root/Launcher/MainLevel/GameManager")
	if gm:
		return gm
		
	gm = get_node_or_null("/root/MainLevel/GameManager")
	if gm:
		return gm
	
	return null

func find_player():
	var p = get_node_or_null("../Player")
	if p:
		return p
	
	var launcher = get_node_or_null("/root/Launcher")
	if launcher and launcher.has("main_level_instance") and launcher.main_level_instance:
		p = launcher.main_level_instance.get_node_or_null("Player")
		if p:
			return p
	
	p = get_node_or_null("/root/Launcher/MainLevel/Player")
	if p:
		return p
		
	p = get_node_or_null("/root/MainLevel/Player")
	if p:
		return p
	
	return null

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
	match GameState.current_mode:
		GameState.GameMode.EDITOR, GameState.GameMode.OBJECT_PLACER:
			editor_panel.visible = true
			racing_panel.visible = false
			var game_manager = find_game_manager()
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
		var game_manager = find_game_manager()
		var race_menu = game_manager.get_node_or_null("RaceMenu") if game_manager else null
		if race_menu and race_menu.visible:
			return

		print("ESC pressed! Pause menu visible =", visible)
		if visible:
			hide_pause_menu()
		else:
			show_pause_menu()

func save_map():
	var game_manager = find_game_manager()
	if game_manager:
		var path = GameState.track_name
		if path == "":
			path = "user://tracks/test1.json"

		var dir = DirAccess.open("user://")
		if dir:
			if not dir.dir_exists("tracks"):
				dir.make_dir("tracks")

		game_manager.save_current_track()
		print("Map saved to ", path)

func start_test_race():
	print("start_test_race() called - button clicked!")
	print("Current pause menu path: ", get_path())
	
	var game_manager = find_game_manager()
	if not game_manager:
		printerr("GameManager not found! Tried multiple paths.")
		printerr("   Current node path: ", get_path())
		return
	
	print("GameManager found at: ", game_manager.get_path())
		
	print("Checking if track is raceable...")
	var is_raceable = game_manager.is_track_raceable()
	print("Track raceable result: ", is_raceable)
	if not is_raceable:
		print("Track is not raceable! (needs start line + checkpoint/finish)")
		print("   Make sure you have placed a start line and at least one checkpoint or finish line")
		return
	
	print("Track is raceable!")
	
	print("Auto-saving before test race...")
	game_manager.save_current_track()
	print("Save completed")
	
	hide_pause_menu()
	
	var player = find_player()
	if not player:
		printerr("Player not found!")
		return
	
	print("Player found at: ", player.get_path())
		
	if not player.mode_manager:
		printerr("Player mode_manager not found!")
		return
	
	print("Player and mode_manager found")
	print("Setting mode to DRIVING...")
	GameState.came_from_editor = true
	GameState.current_mode = GameState.GameMode.DRIVING
	
	game_manager.pending_start_mode = GameState.GameMode.DRIVING
	
	player.mode_manager.set_mode(player.mode_manager.PlayerMode.DRIVING)
	print("Mode change triggered - _on_mode_changed should handle truck spawning and race menu")

func resume_game():
	hide_pause_menu()

func restart_race():
	var game_manager = find_game_manager()
	if game_manager:
		game_manager.restart_race()
		visible = false

func quit_to_menu():
	var game_manager = find_game_manager()
	if game_manager:
		if GameState.current_mode == GameState.GameMode.EDITOR or GameState.current_mode == GameState.GameMode.OBJECT_PLACER or GameState.came_from_editor:
			print("Auto-saving before quit...")
			game_manager.save_current_track()
			print("Save completed.")
	
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var launcher = get_node("/root/Launcher")
	if launcher:
		hide_pause_menu()
		launcher.back_to_main_menu()

func return_to_editor():
	GameState.current_mode = GameState.GameMode.EDITOR
	GameState.came_from_editor = false

	var player = find_player()
	if player and player.mode_manager:
		player.mode_manager.set_mode(player.mode_manager.PlayerMode.EDITOR)

	var game_manager = find_game_manager()
	if game_manager and game_manager.race_hud:
		game_manager.race_hud.queue_free()
		game_manager.race_hud = null

	hide_pause_menu()

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

	var mode_manager = get_node_or_null("/root/MainLevel/ModeManager")
	if mode_manager:
		mode_manager.set_mode(mode_manager.PlayerMode.EDITOR)

	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_quit_pressed():
	get_tree().paused = false
	emit_signal("quit_game")

func reset():
	has_raced_once = false
	race_button.visible = true
	retry_button.visible = false
	visible = true

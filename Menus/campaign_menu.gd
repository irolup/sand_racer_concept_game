extends Control

func _ready():
	#$VBoxContainer/Level1Button.pressed.connect(func(): _start_level("res://Levels/Level1.tscn"))
	#$VBoxContainer/Level2Button.pressed.connect(func(): _start_level("res://Levels/Level2.tscn"))
	$VBoxContainer/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://Menus/main_menu.tscn"))

func _start_level(scene_path: String):
	GameState.current_mode = GameState.GameMode.DRIVING
	get_tree().change_scene_to_file(scene_path)

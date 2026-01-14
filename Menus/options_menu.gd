extends Control

func _ready():
	$VBoxContainer/FullscreenCheckbox.toggled.connect(func(on): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	$VBoxContainer/VolumeSlider.value_changed.connect(func(value): AudioServer.set_bus_volume_db(0, linear_to_db(value)))
	$VBoxContainer/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://Menus/main_menu.tscn"))

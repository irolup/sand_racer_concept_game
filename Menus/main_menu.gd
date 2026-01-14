extends Control

func _ready():
	$VBoxContainer/CampaignButton.pressed.connect(_on_campaign_pressed)
	$VBoxContainer/TracksButton.pressed.connect(_on_tracks_pressed)
	$VBoxContainer/EditorButton.pressed.connect(_on_editor_pressed)
	$VBoxContainer/OptionsButton.pressed.connect(_on_options_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_campaign_pressed(): get_tree().change_scene_to_file("res://Menus/campaign_menu.tscn")

func _on_tracks_pressed():
	if has_meta("launcher"):
		var launcher = get_meta("launcher")
		if launcher:
			launcher.main_menu_instance.visible = false
			launcher.user_tracks_menu_instance.visible = true

func _on_editor_pressed():
	if has_meta("launcher"):
		var launcher = get_meta("launcher")
		if launcher:
			launcher.main_menu_instance.visible = false
			launcher.editor_menu_instance.visible = true
		
func _on_options_pressed(): get_tree().change_scene_to_file("res://Menus/options_menu.tscn")
func _on_quit_pressed(): get_tree().quit()

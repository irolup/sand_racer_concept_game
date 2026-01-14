extends Control

@onready var new_track_popup: Popup = $NewTrackPopup
@onready var name_input: LineEdit = $NewTrackPopup/VBoxContainer/LineEdit
@onready var confirm_button: Button = $NewTrackPopup/VBoxContainer/HBoxContainer/ConfirmButton
@onready var cancel_button: Button = $NewTrackPopup/VBoxContainer/HBoxContainer/CancelButton

func _ready():
	$VBoxContainer/NewTrackButton.pressed.connect(_on_new_track_button_pressed)
	$VBoxContainer/LoadTrackButton.pressed.connect(_load_track)
	$VBoxContainer/BackButton.pressed.connect(_go_back)
	
	confirm_button.pressed.connect(_confirm_new_track)
	cancel_button.pressed.connect(func(): new_track_popup.hide())

func _go_back():
	var launcher = get_meta("launcher")
	if launcher:
		visible = false
		launcher.main_menu_instance.visible = true

func _on_new_track_button_pressed():
	name_input.clear()
	new_track_popup.popup_centered()

func _confirm_new_track():
	var track_name = name_input.text.strip_edges()
	if track_name.is_empty():
		print("Track name is empty.")
		return

	GameState.current_mode = GameState.GameMode.EDITOR
	GameState.track_name = track_name
	var launcher = get_meta("launcher")
	if launcher:
		launcher.start_new_map(track_name)

func _load_track():
	GameState.current_mode = GameState.GameMode.OBJECT_PLACER
	var launcher = get_meta("launcher")
	if launcher:
		visible = false
		launcher.user_tracks_menu_instance.visible = true

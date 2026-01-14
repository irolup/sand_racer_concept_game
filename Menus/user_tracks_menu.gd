extends Control

const TRACK_FOLDER := "user://tracks/"
const ENTRY_HEIGHT := 40  # Approximate height per row
const MAX_SCROLL_HEIGHT := 420

var track_count := 0

func _ready():
	$VBoxContainer/BackButton.pressed.connect(_go_back)

	var scroll_container = $VBoxContainer/ScrollContainer
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(400, 300)

	var track_list_node = scroll_container.get_node("TrackList")
	track_list_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track_list_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_list_node.custom_minimum_size = Vector2(400, 300)

	load_user_tracks()

func _go_back():
	var launcher = get_meta("launcher")
	if launcher:
		visible = false
		launcher.main_menu_instance.visible = true

func load_user_tracks():
	var dir := DirAccess.open(TRACK_FOLDER)
	if dir == null:
		print("Failed to open track folder!")
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			add_track_entry(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func add_track_entry(track_name: String):
	track_count += 1

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label = Label.new()
	label.text = track_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hbox.add_child(label)

	# Load track data to determine if it's raceable
	var track_data = TrackSaver.load_track(track_name.get_basename())
	var is_raceable = track_data.get("raceable", false)
	
	#var launcher = get_meta("launcher")

	# Only show Play button if the track is raceable
	if is_raceable:
		var play_button = Button.new()
		play_button.text = "Play"
		play_button.pressed.connect(func():
			var launcher = get_meta("launcher")  # re-fetch here
			if launcher:
				print(">>> Play clicked, before init: mode=", GameState.current_mode)
				GameState.came_from_editor = false
				GameState.track_name = track_name.get_basename()
				launcher.initialize_main_level(GameState.GameMode.DRIVING)
				print(">>> After init_main_level: mode=", GameState.current_mode)
			else:
				printerr("Launcher was NULL when Play pressed!")
		)
		hbox.add_child(play_button)
	else:
		var play_button = Button.new()
		play_button.text = "Play"
		play_button.disabled = true
		play_button.tooltip_text = "Not raceable: needs start + (checkpoint or finish line)"
		hbox.add_child(play_button)

	# Always show Edit button
	var edit_button = Button.new()
	edit_button.text = "Edit"
	edit_button.pressed.connect(func():
		var launcher = get_meta("launcher")
		if launcher:
			GameState.current_mode = GameState.GameMode.EDITOR
			GameState.track_name = track_name.get_basename()
			launcher.initialize_main_level(GameState.GameMode.EDITOR)
		else:
			printerr("Launcher was NULL when Edit pressed!")
	)
	hbox.add_child(edit_button)

	# Always show Delete button
	var delete_button = Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(func(): delete_track(track_name, hbox))
	hbox.add_child(delete_button)

	var track_list_node = $VBoxContainer/ScrollContainer/TrackList
	track_list_node.add_child(hbox)

	# Adjust scroll container height (up to a max)
	var new_height = min(track_count * ENTRY_HEIGHT, MAX_SCROLL_HEIGHT)
	$VBoxContainer/ScrollContainer.custom_minimum_size.y = new_height


func delete_track(track_name: String, node: Node):
	var path = TRACK_FOLDER + track_name
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Deleted track file:", path)

	PlayerSave.remove_best_time(track_name.get_basename())  # Remove from player save
	node.queue_free()

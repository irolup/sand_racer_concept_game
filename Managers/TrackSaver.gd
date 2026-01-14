extends Node

const TRACKS_DIR := "user://tracks/"
const EXT := ".json"

func get_track_path(track_name: String) -> String:
	return TRACKS_DIR + track_name + EXT

func ensure_tracks_dir():
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("tracks"):
		dir.make_dir("tracks")

func save_track(track_name: String, data: Dictionary) -> bool:
	ensure_tracks_dir()
	var path = get_track_path(track_name)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		printerr("Failed to open file for writing:", path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Saved track to:", path)
	return true

func load_track(track_name: String) -> Dictionary:
	var path = get_track_path(track_name)
	if not FileAccess.file_exists(path):
		printerr("Track file does not exist:", path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		print("Loaded track:", path)
		return parsed
	printerr("Failed to parse JSON in:", path)
	return {}

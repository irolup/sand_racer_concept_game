extends Node

const SAVE_FOLDER := "user://player/"
const SAVE_PATH := SAVE_FOLDER + "player_data.json"
var best_times: Dictionary = {}
var best_lap_data: Dictionary = {}

func _ready():
	load_player_data()

func load_player_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			best_times = data.get("best_times", {})
			best_lap_data = data.get("best_lap_data", {})
			print("Player data loaded.")
		else:
			print("Invalid player save data.")
	else:
		print("No player save found; starting fresh.")
		best_times = {}

func save_player_data():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("player"):
		dir.make_dir("player")

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"best_times": best_times,
		"best_lap_data": best_lap_data
	}, "\t"))
	file.close()
	print("Player data saved.")

func get_best_time(track_name: String) -> float:
	return best_times.get(track_name, 0.0)

func set_best_time(track_name: String, time: float):
	print("set_best_time called for track:", track_name, "time:", time)
	var current_best = best_times.get(track_name, INF)
	if time < current_best:
		best_times[track_name] = time
		save_player_data()
		print("New best time saved: %.2f s for %s" % [time, track_name])

func remove_best_time(track_name: String):
	if best_times.has(track_name):
		best_times.erase(track_name)
		save_player_data()
		print("Removed best time for:", track_name)

func set_best_lap_data(track_name: String, total_time: float, checkpoint_times: Array[float]):
	var data = {
		"total_time": total_time,
		"checkpoint_times": checkpoint_times,
	}
	best_lap_data[track_name] = data
	save_player_data()
	print("Saved best lap data for:", track_name)
	
func get_best_lap_data(track_name: String) -> Dictionary:
	return best_lap_data.get(track_name, {})

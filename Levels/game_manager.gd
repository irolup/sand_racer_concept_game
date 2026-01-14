extends Node

@export var player: CharacterBody3D
#@export var monster_truck: RigidBody3D
@export var monster_truck_scene: PackedScene
@export var march_cude_node: Node3D
@export var object_placer: Node3D

var RaceMenuScene := preload("res://Menus/race_menu.tscn")
var race_menu: Control = null
var race_start_time: float
var best_times := {}
var checkpoint_timestamps: Array[float] = []

var checkpoints_required := []
var checkpoints_passed := []

var starting_line: Node3D
var finish_line: Node3D
var monster_truck: RigidBody3D = null
var pending_spawn_transform: Transform3D = Transform3D.IDENTITY

var RaceTimer := preload("res://Managers/RaceTimer.gd")
var RaceHUDScene := preload("res://Vehicle/race_hud.tscn")
var race_timer: Node = null
var race_hud: Control = null

var pending_start_mode: int = GameState.GameMode.EDITOR

@onready var vehicle_manager: Node = $"../vehicle_manager"

func _ready():
	if player.mode_manager:
		player.mode_manager.connect("mode_changed", Callable(self, "_on_mode_changed"))

	if march_cude_node:
		if march_cude_node.ready:  # <-- pseudo function, replace with your terrain check
			_start_mode_if_pending()
		else:
			march_cude_node.terrain_ready.connect(func():
				_start_mode_if_pending()
			)
	else:
		printerr("❌ march_cude_node is not assigned in GameManager!")


func _process(_delta):
	if player.mode_manager.is_in_mode(player.mode_manager.PlayerMode.EDITOR):
		if march_cude_node.show_preview:
			march_cude_node.process_node(_delta)
			
#func _input(event: InputEvent) -> void:
	#GameState.current_mode = GameState.GameMode.DRIVING
	#if vehicle_manager:
		#vehicle_manager._input(event)

func register_checkpoint(checkpoint: Node) -> void:
	if checkpoint.has_signal("checkpoint_reached"):
		if not checkpoint.is_connected("checkpoint_reached", Callable(self, "_on_checkpoint_reached")):
			checkpoint.checkpoint_reached.connect(_on_checkpoint_reached)
			print("Connected checkpoint signal for ID: ", checkpoint.checkpoint_id)
		else:
			print("Checkpoint signal already connected for ID: ", checkpoint.checkpoint_id)

		if checkpoint.checkpoint_id not in checkpoints_required:
			checkpoints_required.append(checkpoint.checkpoint_id)
			print("Checkpoint registered: %s" % checkpoint.checkpoint_id)

func unregister_checkpoint(checkpoint: Node) -> void:
	if checkpoint.has_signal("checkpoint_reached") and \
			checkpoint.checkpoint_reached.is_connected(_on_checkpoint_reached):
		checkpoint.checkpoint_reached.disconnect(_on_checkpoint_reached)
		print("Disconnected checkpoint signal for ID: ", checkpoint.checkpoint_id)

	if checkpoint.checkpoint_id in checkpoints_required:
		checkpoints_required.erase(checkpoint.checkpoint_id)
		print("Checkpoint unregistered: %s" % checkpoint.checkpoint_id)

	if checkpoint.checkpoint_id in checkpoints_passed:
		checkpoints_passed.erase(checkpoint.checkpoint_id)
		print("Checkpoint removed from passed list: %s" % checkpoint.checkpoint_id)

func _on_checkpoint_reached(checkpoint_id: String) -> void:
	if checkpoint_id in checkpoints_passed:
		return  # Ignore duplicates
	print("Checkpoint reached:", checkpoint_id)
	checkpoints_passed.append(checkpoint_id)
	
	if race_timer:
		var time = race_timer.get_time()
		checkpoint_timestamps.append(time)

		# Split time comparison
		var best_data = PlayerSave.get_best_lap_data(GameState.track_name)
		var best_checkpoints = best_data.get("checkpoint_times", [])

		if checkpoint_timestamps.size() <= best_checkpoints.size():
			var index := checkpoint_timestamps.size() - 1
			if index >= 0 and index < best_checkpoints.size():
				var best_time = best_checkpoints[index]
				var delta = time - best_time
				race_hud.show_split_time(delta)
	
	if race_hud:
		race_hud.update_checkpoints(checkpoints_passed.size(), checkpoints_required.size())
	if race_timer:
		var time = race_timer.get_time()
		print("Checkpoint %s at %.2f seconds" % [checkpoint_id, time])

func _on_finish_line_entered() -> void:	
	print("Required: ", checkpoints_required)
	print("Passed: ", checkpoints_passed)
	if _has_passed_all_checkpoints():
		end_game()
	else:
		print("Not all checkpoints passed.")

func _has_passed_all_checkpoints() -> bool:
	return checkpoints_required.size() == checkpoints_passed.size() \
		and checkpoints_required.all(func(id): return id in checkpoints_passed)

func _on_mode_changed(previous_mode, current_mode):
	if previous_mode == player.mode_manager.PlayerMode.EDITOR and current_mode != player.mode_manager.PlayerMode.EDITOR:
		if march_cude_node and march_cude_node.has_method("clear_preview"):
			march_cude_node.clear_preview()
	
	if current_mode == player.mode_manager.PlayerMode.DRIVING:
		print("➡ Entering DRIVING mode (test race)")
		# Disable the player (already in DRIVING mode from mode_manager)
		player.set_player_enabled(false)
		
		var truck_instance = spawn_monster_truck()
		
		if truck_instance:
			# Switch to truck camera cleanly
			player.smooth_camera.current = false
			if truck_instance.has_node("Camera3D"):
				truck_instance.get_node("Camera3D").current = true
			
			truck_instance.respawn()

			checkpoints_passed.clear()
			race_start_time = Time.get_ticks_msec() / 1000.0
			show_race_menu()

	elif current_mode == player.mode_manager.PlayerMode.EDITOR:
		print("⬅ Returning to EDITOR mode")
		# Clean up monster truck from both references
		if monster_truck:
			if is_instance_valid(monster_truck):
				monster_truck.queue_free()
			monster_truck = null
		
		if vehicle_manager.truck:
			if is_instance_valid(vehicle_manager.truck):
				vehicle_manager.truck.queue_free()
			vehicle_manager.set_truck(null)
		
		# Switch back to player camera and enable player
		# Note: Don't set mode_manager mode here - it's already set, and setting it would cause recursion
		player.set_player_enabled(true)
		player.smooth_camera.current = true

func restart_race():
	print("🔄 Restarting race...")

	# Clear passed checkpoints
	checkpoints_passed.clear()

	# Unpause the game and reset mouse mode
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Reset the monster truck to the spawn position
	if monster_truck and starting_line and starting_line.has_method("get_spawn_transform"):
		monster_truck.set_respawn(starting_line.get_spawn_transform())
		monster_truck.respawn()

	# Reset the race timer
	race_start_time = Time.get_ticks_msec() / 1000.0

	print("✅ Race restarted. Timer and checkpoints cleared.")

func end_game():
	print("🏁 You Win!")
	monster_truck.respawn()
	checkpoints_passed.clear()

	if race_timer:
		race_timer.pause()
		var duration = race_timer.get_time()
		var current_best = PlayerSave.get_best_time(GameState.track_name)

		if current_best == 0.0 or duration < current_best:
			PlayerSave.set_best_time(GameState.track_name, duration)

		# Always save best lap data if it's a better or equal duration
		if duration <= current_best or current_best == 0.0:
			PlayerSave.set_best_lap_data(GameState.track_name, duration, checkpoint_timestamps)
	else:
		print("⚠️ RaceTimer not found!")
		var end_time = Time.get_ticks_msec() / 1000.0
		var duration = end_time - race_start_time

	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	show_race_menu()

	if race_hud:
		race_hud.visible = false

func set_finish_line(new_finish_line: Node3D) -> void:
	finish_line = new_finish_line
	if not finish_line.is_connected("car_reached_finish", _on_finish_line_entered):
		finish_line.connect("car_reached_finish", _on_finish_line_entered)
		
func set_starting_line(new_starting_line: Node3D) -> void:
	starting_line = new_starting_line
	if starting_line.has_method("get_spawn_transform"):
		pending_spawn_transform = starting_line.get_spawn_transform()
		print("have function get_Spawn_transform")
		if monster_truck:
			monster_truck.set_respawn(pending_spawn_transform)
			print("we have vehicule and new global", monster_truck.spawn_position)
	else:
		print("doesnt have method")
	# Optionally set it as finish line too
	if starting_line.has_signal("car_reached_finish") and \
	   "is_finish_line" in starting_line.get_property_list().map(func(p): return p.name) and \
	   starting_line.is_finish_line:
		print("set finish line start")
		set_finish_line(starting_line)

func clear_finish_line() -> void:
	if finish_line and finish_line.has_signal("car_reached_finish") \
			and finish_line.car_reached_finish.is_connected(_on_finish_line_entered):
		finish_line.car_reached_finish.disconnect(_on_finish_line_entered)
		print("Finish line signal disconnected.")

	finish_line = null


func save_map(file_path: String) -> void:
	var save_data = {}

	# ✅ Save voxel data (check if the node has the voxel_data property)
	if march_cude_node != null and "voxel_data" in march_cude_node:
		save_data["voxel_data"] = Array(march_cude_node.voxel_data)

	# ✅ Save placed objects
	var placed_objects = []
	var container = object_placer.get_node("PlacedObjects")
	for child in container.get_children():
		var obj_data = {
			"position": child.position,
			"rotation": child.rotation,
			"scale": child.scale,
			"scene_path": child.get_meta("source_scene_path") if child.has_meta("source_scene_path") else "",
		}
		var area = child.get_node_or_null("Area3D")
		if area and area.has_meta("checkpoint_id"):
			obj_data["checkpoint_id"] = area.get_meta("checkpoint_id")
		
		placed_objects.append(obj_data)
	save_data["placed_objects"] = placed_objects

	# ✅ Write to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
	else:
		print("Failed to open file for saving.")


func load_map(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		print("Map file doesn't exist:", file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var save_data = JSON.parse_string(file.get_as_text())
	file.close()

	if not save_data:
		print("Failed to parse map file.")
		return

	# ✅ Load voxel data
	if save_data.has("voxel_data") and march_cude_node != null:
		march_cude_node.voxel_data = PackedFloat32Array(save_data["voxel_data"])
		if march_cude_node.has_method("update_all_chunks"):
			march_cude_node.update_all_chunks()

	# ✅ Clear and load placed objects
	var container = object_placer.get_node("PlacedObjects")
	for child in container.get_children():
		child.queue_free()

	if save_data.has("placed_objects"):
		for obj_data in save_data["placed_objects"]:
			var scene_path = obj_data.get("scene_path", "")
			if scene_path == "":
				print("Warning: scene_path missing in saved object data")
				continue
			
			var packed_scene = load(scene_path)
			if packed_scene == null or not packed_scene is PackedScene:
				print("Failed to load PackedScene at: ", scene_path)
				continue

			var instance = packed_scene.instantiate()
			container.add_child(instance)
			var pos_vec = str_to_vector3(obj_data["position"])
			var rot_vec = str_to_vector3(obj_data["rotation"])
			var scale_vec = str_to_vector3(obj_data["scale"])

			var transform = instance.global_transform
			transform.origin = pos_vec
			instance.global_transform = transform

			instance.rotation = rot_vec
			instance.scale = scale_vec
			if instance.is_in_group("checkpoints"):
				print("Loaded object is a checkpoint")
				var area = instance.get_node_or_null("Area3D")
				if area:
					# Restore checkpoint_id if available
					if obj_data.has("checkpoint_id"):
						area.checkpoint_id = obj_data["checkpoint_id"]
					else:
						print("⚠️ Warning: checkpoint_id missing in saved data. Skipping registration.")
						continue  # Skip this checkpoint if no ID

					register_checkpoint(area)
			elif instance.is_in_group("finish_lines"):
				var area = instance.get_node_or_null("Area3D")
				if area and not area.is_connected("car_reached_finish", Callable(self, "_on_finish_line_entered")):
					area.car_reached_finish.connect(Callable(self, "_on_finish_line_entered"))
					set_finish_line(area)
			elif instance.is_in_group("starting_lines"):
				set_starting_line(instance)

	print("Map loaded from: ", file_path)

func str_to_vector3(s: String) -> Vector3:
	# Remove the leading and trailing parentheses manually
	if s.begins_with("(") and s.ends_with(")"):
		s = s.substr(1, s.length() - 2)

	var parts = s.split(",")
	if parts.size() != 3:
		return Vector3.ZERO

	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())


func collect_game_data() -> Dictionary:
	var save_data := {}

	if march_cude_node != null and "voxel_data" in march_cude_node:
		save_data["voxel_data"] = Array(march_cude_node.voxel_data)

	var placed_objects = []
	var container = object_placer.get_node("PlacedObjects")
	var has_start := false
	var has_checkpoint := false
	var has_finish := false
	for child in container.get_children():
		var obj_data = {
			"position": child.position,
			"rotation": child.rotation,
			"scale": child.scale,
			"scene_path": child.get_meta("source_scene_path") if child.has_meta("source_scene_path") else "",
		}
		
		if child.is_in_group("starting_lines"):
			has_start = true
		elif child.is_in_group("checkpoints"):
			has_checkpoint = true
		elif child.is_in_group("finish_lines"):
			has_finish = true
		
		var area = child.get_node_or_null("Area3D")
		if area and area.has_meta("checkpoint_id"):
			obj_data["checkpoint_id"] = area.checkpoint_id
		placed_objects.append(obj_data)
	save_data["placed_objects"] = placed_objects
	
	var raceable := false
	if has_start:
		raceable = has_checkpoint or has_finish
	save_data["raceable"] = raceable
	
	if player:
		save_data["player_transform"] = {
			"position": player.global_transform.origin,
			"rotation": player.global_transform.basis.get_euler()
		}

	return save_data

func apply_game_data(save_data: Dictionary) -> void:
	if save_data.has("voxel_data") and march_cude_node != null:
		march_cude_node.voxel_data = PackedFloat32Array(save_data["voxel_data"])
		call_deferred("_deferred_update_chunks")

	var container = object_placer.get_node("PlacedObjects")
	for child in container.get_children():
		child.queue_free()

	if save_data.has("placed_objects"):
		for obj_data in save_data["placed_objects"]:
			var scene_path = obj_data.get("scene_path", "")
			if scene_path == "":
				print("Warning: scene_path missing in saved object data")
				continue

			var packed_scene = load(scene_path)
			if packed_scene == null or not packed_scene is PackedScene:
				print("Failed to load PackedScene at: ", scene_path)
				continue

			var instance = packed_scene.instantiate()
			instance.set_meta("source_scene_path", scene_path)
			container.add_child(instance)
			var pos_vec = str_to_vector3(obj_data["position"])
			var rot_vec = str_to_vector3(obj_data["rotation"])
			var scale_vec = str_to_vector3(obj_data["scale"])

			var transform = instance.global_transform
			transform.origin = pos_vec
			instance.global_transform = transform

			instance.rotation = rot_vec
			instance.scale = scale_vec

			if instance.is_in_group("checkpoints"):
				var area = instance.get_node_or_null("Area3D")
				if area and obj_data.has("checkpoint_id"):
					area.checkpoint_id = obj_data["checkpoint_id"]
					register_checkpoint(area)

			elif instance.is_in_group("finish_lines"):
				var area = instance.get_node_or_null("Area3D")
				if area and not area.is_connected("car_reached_finish", Callable(self, "_on_finish_line_entered")):
					area.car_reached_finish.connect(Callable(self, "_on_finish_line_entered"))
					set_finish_line(area)

			elif instance.is_in_group("starting_lines"):
				set_starting_line(instance)
				
	if save_data.has("player_transform") and player:
		var t = save_data["player_transform"]
		player.global_transform.origin = str_to_vector3(t.position)
		player.rotation = str_to_vector3(t.rotation)

func _deferred_update_chunks():
	if march_cude_node.has_method("update_all_chunks"):
		march_cude_node.update_all_chunks()

func save_current_track():
	if GameState.track_name == "":
		print("❌ No track name in GameState.")
		return
	var data = collect_game_data()
	TrackSaver.save_track(GameState.track_name, data)

func load_current_track(start_mode: int = GameState.GameMode.EDITOR):
	pending_start_mode = start_mode
	
	# Clean up any existing vehicles before loading a new track
	if monster_truck:
		if is_instance_valid(monster_truck):
			monster_truck.queue_free()
		monster_truck = null
	
	if vehicle_manager.truck:
		if is_instance_valid(vehicle_manager.truck):
			vehicle_manager.truck.queue_free()
		vehicle_manager.set_truck(null)
	
	if GameState.track_name == "":
		print("❌ No track name in GameState.")
		return
	var data = TrackSaver.load_track(GameState.track_name)
	if data.is_empty():
		print("❌ Track data is empty or failed to load.")
		return
	apply_game_data(data)
	print("✅ Loaded track:", GameState.track_name)
	if march_cude_node and march_cude_node.ready:
		print("🟢 Terrain ready, running _start_mode_if_pending")
		_start_mode_if_pending()

func show_race_menu():
	if race_menu == null:
		race_menu = RaceMenuScene.instantiate()
		add_child(race_menu)

		# Connect signals once here
		race_menu.start_race.connect(_on_race_start)
		race_menu.retry_race.connect(_on_race_retry)
		race_menu.visible = pending_start_mode != GameState.GameMode.EDITOR
		race_menu.quit_game.connect(_on_race_quit)
	else:
		race_menu.reset()

	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var best = PlayerSave.get_best_time(GameState.track_name)
	race_menu.set_best_time(best)

func _on_race_start():
	# Clean up previous HUD if it exists
	if race_hud:
		race_hud.queue_free()
		race_hud = null

	# Clean up previous timer if needed
	if race_timer:
		race_timer.queue_free()
		race_timer = null

	# Spawn and start RaceTimer
	checkpoint_timestamps.clear()
	race_timer = RaceTimer.new()
	add_child(race_timer)
	race_timer.start()

	# Spawn and show RaceHUD
	race_hud = RaceHUDScene.instantiate()
	add_child(race_hud)

	var best = PlayerSave.get_best_time(GameState.track_name)
	race_hud.set_best_time(best)

	# Connect live timer updates
	race_timer.time_updated.connect(race_hud.update_time)

	# Initialize checkpoints label
	if checkpoints_required.size() > 0:
		race_hud.update_checkpoints(0, checkpoints_required.size())

	# Hide any leftover split time display
	race_hud.split_time_label.visible = false

	race_menu.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_race_retry():
	# Reset the race without reloading the scene
	checkpoints_passed.clear()

	if monster_truck:
		monster_truck.respawn()

	race_start_time = Time.get_ticks_msec() / 1000.0

	if race_menu:
		race_menu.visible = false

	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_race_quit():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")


func spawn_monster_truck() -> Node:
	# Clean up any existing truck first
	if monster_truck:
		monster_truck.queue_free()
		monster_truck = null
	
	if vehicle_manager.truck:
		vehicle_manager.truck.queue_free()
		vehicle_manager.set_truck(null)
	
	if monster_truck_scene:
		var truck_instance = monster_truck_scene.instantiate()
		add_child(truck_instance)
		monster_truck = truck_instance  # Store reference
		vehicle_manager.set_truck(truck_instance)  # Set in vehicle manager
		if pending_spawn_transform:
			truck_instance.set_respawn(pending_spawn_transform)
		return truck_instance
	return null

func start_test_race_in_place():

	GameState.current_mode = GameState.GameMode.DRIVING

	# Hide editor tools if needed and set player mode to DRIVING
	player.set_player_enabled(false)
	if player.mode_manager:
		player.mode_manager.set_mode(player.mode_manager.PlayerMode.DRIVING)

	# Spawn vehicle if needed
	if not monster_truck:
		spawn_monster_truck()
		await get_tree().process_frame  # Let physics settle before respawn

	monster_truck.set_respawn(starting_line.get_spawn_transform())
	monster_truck.respawn()

	# Enable camera
	player.camera_monster_truck.current = true

	# Reset race logic
	checkpoints_passed.clear()
	race_start_time = Time.get_ticks_msec() / 1000.0

	# Switch UI
	show_race_menu()


func is_track_raceable() -> bool:
	var data = collect_game_data()
	return data.has("raceable") and data["raceable"]

func start_mode(mode: int):
	print(">>> start_mode called with ", mode)
	if mode == GameState.GameMode.DRIVING:
		print(">>> Entering DRIVING mode")
		GameState.current_mode = GameState.GameMode.DRIVING
	else:
		print(">>> Entering EDITOR mode")
		GameState.current_mode = GameState.GameMode.EDITOR

func _start_mode_if_pending():

	if pending_start_mode == GameState.GameMode.DRIVING:
		GameState.came_from_editor = false
		
		# Disable the player and set mode to DRIVING (only if not already in DRIVING mode)
		player.set_player_enabled(false)
		if player.mode_manager and not player.mode_manager.is_in_mode(player.mode_manager.PlayerMode.DRIVING):
			player.mode_manager.set_mode(player.mode_manager.PlayerMode.DRIVING)
		
		var truck_instance = spawn_monster_truck()
		if not truck_instance:
			printerr("spawn_monster_truck returned null")
		else:
			# Switch to truck camera
			player.smooth_camera.current = false
			var truck_camera = truck_instance.get_node_or_null("Camera3D")
			if truck_camera:
				truck_camera.current = true
			else:
				printerr("Truck camera not found")
			show_race_menu()
			truck_instance.respawn()

	GameState.current_mode = pending_start_mode
	print(" current_mode after _start_mode_if_pending:", GameState.current_mode)
	pending_start_mode = GameState.GameMode.EDITOR

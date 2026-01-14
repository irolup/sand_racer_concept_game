extends Node

var truck: Node = null

func set_truck(new_truck: Node):
	truck = new_truck

func _physics_process(delta: float) -> void:
	if truck and is_instance_valid(truck):
		if truck.has_method("handleInput"):
			truck.handleInput(delta)
		
		# Handle truck camera updates
		if truck.has_node("Camera3D"):
			var cam: Camera3D = truck.get_node("Camera3D")
			if cam.has_method("physics_process_camera"):
				cam.physics_process_camera()
	else:
		return

func _unhandled_input(event: InputEvent) -> void:
	if truck and is_instance_valid(truck):
		if truck.has_node("Camera3D"):
			var cam: Camera3D = truck.get_node("Camera3D")
			if cam.has_method("unhandled_input_camera"):
				cam.unhandled_input_camera(event)
	else:
		return

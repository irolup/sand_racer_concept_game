extends Node3D

@export var is_finish_line: bool = false

@onready var area_3d: Area3D = $Area3D

signal car_reached_finish

func _ready():
	if area_3d:
		area_3d.connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if is_finish_line and body is VehicleBody3D:
		car_reached_finish.emit()

func get_spawn_transform() -> Transform3D:
	return global_transform

extends Area3D

@export var is_finish_line := true # For future checkpoint vs finish reuse

signal car_reached_finish

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("vehicules"):
		car_reached_finish.emit()

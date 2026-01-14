extends Area3D

@export var checkpoint_id: String
signal checkpoint_reached(checkpoint_id: String)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("vehicules"):  # Assuming your player extends CharacterBody3D
		print("Checkpoint reached! Emitting signal for ", checkpoint_id)
		checkpoint_reached.emit(checkpoint_id)

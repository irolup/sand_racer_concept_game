@tool
extends Control
#@onready var label: Label = $"../../Label"

func _ready() -> void:
	_update_crosshair_layout()
	
#func _process(_delta: float) -> void:
	## Update FPS every frame
	#label.text = "FPS: %d" % Engine.get_frames_per_second()

func _update_crosshair_layout() -> void:
	# Get the window size
	var window_size := get_window().size
	
	# Resize the parent CenterContainer to match the window size
	var parent := get_parent()
	if parent and parent is Control:
		parent.set_size(window_size)

	# Schedule a redraw
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4, Color.DIM_GRAY)
	draw_circle(Vector2.ZERO, 3, Color.WHITE)

	draw_line(Vector2(16, 0), Vector2(24, 0), Color.WHITE, 2)
	draw_line(Vector2(-16, 0), Vector2(-24, 0), Color.WHITE, 2)
	draw_line(Vector2(0, 16), Vector2(0, 24), Color.WHITE, 2)
	draw_line(Vector2(0, -16), Vector2(0, -24), Color.WHITE, 2)

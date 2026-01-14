extends Control

@onready var timer_label: Label = $VBoxContainer/TimerLabel
@onready var best_time_label: Label = $VBoxContainer/BestTimeLabel
@onready var checkpoints_label: Label = $VBoxContainer/CheckpointsLabel
@onready var split_time_label: Label = $VBoxContainer/SplitTimeLabel
@onready var split_timer := Timer.new()

func _ready():
	add_child(split_timer)
	split_timer.wait_time = 1.5
	split_timer.one_shot = true
	split_timer.timeout.connect(_on_split_timeout)

func update_time(seconds: float):
	timer_label.text = "%.2f" % seconds

func set_best_time(seconds: float):
	best_time_label.text = "Best: %.2f" % seconds

func update_checkpoints(passed: int, required: int):
	checkpoints_label.text = "Checkpoints: %d / %d" % [passed, required]

func show_split_time(delta: float):
	if delta > 0.0:
		split_time_label.text = "+%.2f" % delta
		split_time_label.modulate = Color.RED
	else:
		split_time_label.text = "%.2f" % delta
		split_time_label.modulate = Color.GREEN

	split_time_label.visible = true
	split_timer.start()
	
func _on_split_timeout():
	split_time_label.visible = false

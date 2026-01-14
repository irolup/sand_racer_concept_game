extends Node

signal time_updated(time: float)

var start_time := 0.0
var elapsed_time := 0.0
var paused := false
var pause_time := 0.0

func _ready():
	set_process(false)

func start():
	start_time = Time.get_ticks_msec() / 1000.0
	elapsed_time = 0.0
	paused = false
	pause_time = 0.0
	set_process(true)

func pause():
	if not paused:
		paused = true
		pause_time = Time.get_ticks_msec() / 1000.0
		set_process(false)

func resume():
	if paused:
		var now = Time.get_ticks_msec() / 1000.0
		var paused_duration = now - pause_time
		start_time += paused_duration
		paused = false
		set_process(true)

func get_time() -> float:
	if paused:
		return pause_time - start_time
	return (Time.get_ticks_msec() / 1000.0) - start_time

func _process(_delta):
	emit_signal("time_updated", get_time())

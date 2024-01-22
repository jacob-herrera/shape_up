extends Control

@onready var timer: Label = $Timer

var time: float = 100.000

func _process(delta: float) -> void:
	time -= delta
	timer.text = "%.3f" % time

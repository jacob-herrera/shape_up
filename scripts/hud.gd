extends Control

@onready var timer: Label = $Timer
@onready var scoped: TextureRect = $Scoped
@onready var fps: Label = $FPS


var time: float = 100.000

func _process(delta: float) -> void:
	time -= delta
	timer.text = "%.3f" % time

	scoped.visible = Controls.get_sniper_scope()
	
	fps.text = "FPS: %d" % Engine.get_frames_per_second()

#func set_scope(vis: bool) -> void:
	#scoped.visible = vis

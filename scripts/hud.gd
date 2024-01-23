extends Control

@onready var timer: Label = $Timer
@onready var scoped: TextureRect = $Scoped

var time: float = 100.000

func _process(delta: float) -> void:
	time -= delta
	timer.text = "%.3f" % time

	scoped.visible = Controls.get_sniper_scope()

#func set_scope(vis: bool) -> void:
	#scoped.visible = vis

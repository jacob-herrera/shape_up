extends Control

@onready var timer: Label = $Timer
@onready var scoped: TextureRect = $Scoped
@onready var fps: Label = $FPS
@onready var music: AudioStreamPlayer = $TempMusic

var time: float = 100.000
var start_ms: int
var pervious_ms: int

func _ready() -> void:
	start_ms = Time.get_ticks_msec()
	pervious_ms = start_ms

func _process(delta: float) -> void:
	if Menu.enabled:
		pervious_ms = Time.get_ticks_msec()
		return
		
	var current_ms: float = Time.get_ticks_msec()
	var ms_diff: float = current_ms - pervious_ms
	pervious_ms = current_ms
	time -= (ms_diff / 1000.00 * Controls.clock_speed)
	timer.text = "%.2f" % time
	
	music.pitch_scale = Controls.clock_speed

	scoped.visible = Controls.get_sniper_scope()
	
	fps.text = "FPS: %d" % Engine.get_frames_per_second()

#func set_scope(vis: bool) -> void:
	#scoped.visible = vis

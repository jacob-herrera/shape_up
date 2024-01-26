extends Control

@onready var timer: Label = $Timer
@onready var scoped: TextureRect = $Scoped
@onready var fps: Label = $FPS
@onready var crosshair: Control = $CenterContainer
@onready var ammo: Label = $Ammo

@onready var second_hand: Control = $SecondHand
@onready var minute_hand: Control = $MinuteHand
@onready var hour_hand: Control = $HourHand


var time: float = 100.000
var start_ms: int
var pervious_ms: int

func _ready() -> void:
	start_ms = Time.get_ticks_msec()
	pervious_ms = start_ms
	PitchChanger.register_player($TempMusic)

func _process(_dt: float) -> void:
	if Menu.enabled:
		pervious_ms = Time.get_ticks_msec()
		return
		
	var current_ms: int = Time.get_ticks_msec()
	var ms_diff: float = current_ms - pervious_ms
	pervious_ms = current_ms
	time -= (ms_diff / 1000.00 * Controls.clock_speed)
	timer.text = "%.2f" % time
	
	ammo.text = str(BulletServer.valid_bullets)
	#music.pitch_scale = Controls.clock_speed
	#print(pitch.pitch_scale)
	second_hand.rotation = time * -8
	minute_hand.rotation = time * 4
	hour_hand.rotation = time * -2

	scoped.visible = Controls.get_sniper_scope()
	crosshair.visible = not scoped.visible
	
	fps.text = "FPS: %d" % Engine.get_frames_per_second()

#func set_scope(vis: bool) -> void:
	#scoped.visible = vis

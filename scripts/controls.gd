extends Node

var wish_jump: bool = false

const PRIMARY_FIRERATE: float = 4.0/60.0
var primary_timer: float = 0

const SHOTGUN_COOLDOWN: float = 6.0/60.0
var shotgun_click_window: float = 100
var shotgun_window: float = 0
var shotgun_cooldown: float = 0.0

const SNIPER_DEBOUNCE: int = 200
var sniper_scoped: bool = false
var sniper_debounce: int = 0
var sniper_charge: float = 0.0

const FAST_SPEED: float = 2.0
const SLOW_SPEED: float = 0.5
var clock_speed: float = 1.0
var target_clock_speed: float = 1.0
var TIME_RAMP_LERP: float = 15.0

var slow_toggle: bool
var fast_toggle: bool

const DASH_METER_MAX: float = 3.0
const DASH_REFILL_RATE: float = 0.25
var dash_meter: float = 3.0

const FREEZE_FRAME_MS: int = 75
var freeze_frames: int = 0

var previous_ms: int

var is_dead: bool = false
var dead_timer: float = 0.0

signal entered_scope
signal exited_scope
#signal parry
signal death

func _ready() -> void:
	#Engine.max_fps = 60
	previous_ms = Time.get_ticks_msec()

func _handle_clock(ms_diff: int) -> void:
	if is_dead:
		Engine.time_scale = 0
		target_clock_speed = 0.0
		clock_speed = 0.0
		return
	
	if freeze_frames > 0:
		Engine.time_scale = 0
		freeze_frames -= ms_diff
		return
	
	if HUD.pause_timer:
		dash_meter = 0.0
		Engine.time_scale = 0.5
		target_clock_speed = 0.5
		clock_speed = 0.5
		return
	
	if SceneManager.scene == SceneManager.Scene.TUTORIAL_1 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_2 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_3 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_4 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_5:
		return
	
	var slow: bool = Input.is_action_pressed("slow")
	var fast: bool = Input.is_action_pressed("fast")
	if Input.is_action_just_released("slowtoggle"):
		slow_toggle = !slow_toggle
		fast_toggle = false
	if Input.is_action_just_released("fasttoggle"):
		fast_toggle = !fast_toggle
		slow_toggle = false
	if (slow and fast) or (not slow and not fast and not slow_toggle and not fast_toggle):
		Engine.time_scale = 1.0
		target_clock_speed = 1.0
	elif slow:
		Engine.time_scale = SLOW_SPEED
		target_clock_speed = FAST_SPEED
	elif fast:
		Engine.time_scale = FAST_SPEED
		target_clock_speed = SLOW_SPEED
	elif slow_toggle:
			Engine.time_scale = SLOW_SPEED
			target_clock_speed = FAST_SPEED
	elif fast_toggle:
			Engine.time_scale = FAST_SPEED
			target_clock_speed = SLOW_SPEED
	var dt: float = ms_diff / 1000.0
	var t: float = pow(0.5, dt * TIME_RAMP_LERP)
	clock_speed = lerpf(target_clock_speed, clock_speed, t)


func invoke_player_death() -> void:
	if not is_dead and not Character.invincible:
		is_dead = true
		sniper_scoped = false
		emit_signal("death")


func hard_reset() -> void:
	PitchChanger.stop_all_sfx()
	slow_toggle = false
	fast_toggle = false
	Controls.clock_speed = 1.0
	wish_jump = false
	Character.reset()
	BulletServer.reset()
	HUD.reset()
	dash_meter = DASH_METER_MAX
	is_dead = false
	dead_timer = 0.0
	sniper_charge = 0.0
	sniper_scoped = false
	Menu.reset()

	if get_tree().current_scene != null:
		get_tree().reload_current_scene()

func _process(delta) -> void:
	# TODO
	#print("Shotgun click window: ", shotgun_click_window)
	if Input.is_action_just_pressed("restart") and not Menu.enabled:
		hard_reset()
		return
	
	var current_ms: int = Time.get_ticks_msec()
	var ms_diff: int = current_ms - previous_ms
	previous_ms = current_ms
	
	if Menu.enabled: return
	
	_handle_clock(ms_diff)
	
	if is_dead:
		dead_timer += ms_diff / 1000.0
		if dead_timer >= 5.3:
			hard_reset()
		return
	#else if 

	
	dash_meter += delta * DASH_REFILL_RATE
	dash_meter = clampf(dash_meter, 0.0, DASH_METER_MAX)
	shotgun_window -= ms_diff		
	primary_timer -= delta
	shotgun_cooldown -= delta
	sniper_debounce -= ms_diff
	
	wish_jump = Input.is_action_pressed("moveup")
	
	if sniper_scoped:
		sniper_charge += delta * 1.75
		sniper_charge = clampf(sniper_charge, 0.0, 1.0)
	else:
		sniper_charge = 0.0
	
	if Input.is_action_just_pressed("attackprimary"):
		if not sniper_scoped and sniper_debounce < 0:
			shotgun_window = shotgun_click_window
	
	if Input.is_action_just_pressed("attacksecondary"):
		if SceneManager.scene == SceneManager.Scene.TUTORIAL_1 \
		or SceneManager.scene == SceneManager.Scene.TUTORIAL_2 \
		or SceneManager.scene == SceneManager.Scene.TUTORIAL_6:
			return
		if not sniper_scoped:
			if BulletServer.bolt_state == BulletServer.BoltState.COLLECTED:
				sniper_scoped = true
				emit_signal("entered_scope")
			elif Character.invincible == false:
				Character.sfx_sniper_error.play()
		else:
			sniper_scoped = false
			sniper_charge = 0.0
			emit_signal("exited_scope")
			
	

	
func get_auto_attack() -> bool:
	if SceneManager.scene == SceneManager.Scene.TUTORIAL_3 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_4 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_6:
		return false
	
	if sniper_scoped or \
	sniper_debounce > 0 or \
	shotgun_window >= 0 or \
	Input.is_action_just_pressed("attackprimary"):
		return false

	var try_fire = Input.is_action_pressed("attackprimary") or Input.is_action_just_released("attackprimary")
	if primary_timer <= 0 and try_fire:
		primary_timer = PRIMARY_FIRERATE
		return true
		
	return false
	
func get_shotgun_attack() -> bool:
	if SceneManager.scene == SceneManager.Scene.TUTORIAL_3 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_4\
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_6:
		return false	

	if sniper_scoped or shotgun_cooldown > 0:
		return false
	var is_released = Input.is_action_just_released("attackprimary")
	if is_released and shotgun_window >= 0:
		shotgun_cooldown = SHOTGUN_COOLDOWN
		return true
	return false
	
func get_sniper_scope() -> bool:
	if BulletServer.bolt_state != BulletServer.BoltState.COLLECTED: return false
	return sniper_scoped
	
func get_sniper_attack() -> bool:
	if BulletServer.bolt_state != BulletServer.BoltState.COLLECTED: return false
	if sniper_scoped:
		if Input.is_action_just_pressed("attackprimary"):
			sniper_scoped = false
			sniper_debounce = SNIPER_DEBOUNCE
			emit_signal("exited_scope")
			return true
	return false

func get_move_input() -> Vector2:
	return Input.get_vector("moveleft", "moveright", "movebackward", "moveforward")
 
func get_try_parry() -> bool:
	if SceneManager.scene == SceneManager.Scene.TUTORIAL_1 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_2 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_3 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_4 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_5:
		return false
	if Input.is_action_just_pressed("parry"):
		return true
	return false

func try_dash() -> int:
	if SceneManager.scene == SceneManager.Scene.TUTORIAL_1 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_2 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_3 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_4 \
	or SceneManager.scene == SceneManager.Scene.TUTORIAL_6:
		return 0
	if Input.is_action_just_pressed("dash"):
		if dash_meter >= 1.0:
			dash_meter -= 1.0
			return 1
		return 2
	return 0
	
func _on_value_changed(value):
	shotgun_click_window = value

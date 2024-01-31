extends Node

var wish_jump: bool = false

const PRIMARY_FIRERATE: float = 2.0/60.0
var primary_timer: float = 0

const SHOTGUN_COOLDOWN: float = 12.0/60.0
const SHOTGUN_CLICK_WINDOW: int = 100
var shotgun_window: int = 0
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
signal parry
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
	
	#if eng
	
	var slow: bool = Input.is_action_pressed("slow")
	var fast: bool = Input.is_action_pressed("fast")
	if (slow and fast) or (not slow and not fast):
		Engine.time_scale = 1.0
		target_clock_speed = 1.0
	elif slow:
		Engine.time_scale = SLOW_SPEED
		target_clock_speed = FAST_SPEED
	elif fast:
		Engine.time_scale = FAST_SPEED
		target_clock_speed = SLOW_SPEED
	var dt: float = ms_diff / 1000.0
	var t: float = pow(0.5, dt * TIME_RAMP_LERP)
	clock_speed = lerpf(target_clock_speed, clock_speed, t)


func invoke_player_death() -> void:
	if not is_dead:
		is_dead = true
		sniper_scoped = false
		emit_signal("death")


func hard_reset() -> void:
	Controls.clock_speed = 1.0
	wish_jump = false
	get_tree().reload_current_scene()
	Character.reset()
	BulletServer.reset()
	HUD.reset()
	dash_meter = DASH_METER_MAX
	is_dead = false
	dead_timer = 0.0
	sniper_charge = 0.0
	sniper_scoped = false

func _process(delta) -> void:
	
	if Input.is_action_just_pressed("restart"):
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
			#print("reload")
			
		
		return
	

	
	dash_meter += delta * DASH_REFILL_RATE
	dash_meter = clampf(dash_meter, 0.0, DASH_METER_MAX)
	shotgun_window -= ms_diff		
	primary_timer -= delta
	shotgun_cooldown -= delta
	sniper_debounce -= ms_diff
	
	if sniper_scoped:
		sniper_charge += delta / 2.0
		sniper_charge = clampf(sniper_charge, 0.0, 1.0)
	else:
		sniper_charge = 0.0
	
	if Input.is_action_just_pressed("attackprimary"):
		if not sniper_scoped and sniper_debounce < 0:
			shotgun_window = SHOTGUN_CLICK_WINDOW
	
	if Input.is_action_just_pressed("attacksecondary"):
		if not sniper_scoped and BulletServer.bolt_state == BulletServer.BoltState.COLLECTED:
			sniper_scoped = true
			emit_signal("entered_scope")
		else:
			sniper_scoped = false
			sniper_charge = 0.0
			emit_signal("exited_scope")
			
	

	wish_jump = Input.is_action_pressed("moveup")

func get_auto_attack() -> bool:
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
	if Input.is_action_just_pressed("parry"):
		emit_signal("parry")
		freeze_frames = FREEZE_FRAME_MS
		return true
	return false

func try_dash() -> int:
	if Input.is_action_just_pressed("dash"):
		if dash_meter >= 1.0:
			dash_meter -= 1.0
			return 1
		return 2
	return 0

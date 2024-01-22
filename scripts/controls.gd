extends Node

const AUTO_JUMP: bool = true
var wish_jump: bool = false

var freeze: bool = false

const PRIMARY_FIRERATE: float = 6/60
var primary_timer: float = 0

# Set wish_jump depending on player input.
func _process(delta) -> void:
	if freeze:
		wish_jump = false
		return
		
	primary_timer -= delta
	
	if AUTO_JUMP: # The player keeps jumping as long as 'jump' is held
		wish_jump = true if Input.is_action_pressed("moveup") else false
	else: # Otherwise buffer the jumps, as long as 'jump' is held
		if Input.is_action_just_pressed("moveup") and !wish_jump:
			wish_jump = true
		if Input.is_action_just_released("moveup"):
			wish_jump = false

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var event: InputEventMouseButton = e as InputEventMouseButton
		var is_mb1: bool = event.button_index == MouseButton.MOUSE_BUTTON_LEFT
		#if is_mb1 and event.pressed:
		#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func get_primary_attack() -> bool:
	var is_pressed = Input.is_action_pressed("attackprimary")
	if is_pressed and primary_timer <= 0:
		primary_timer = PRIMARY_FIRERATE
		return true
	return false
		
func get_move_input() -> Vector2:
	if freeze:
		return Vector2.ZERO
	var move_dir: Vector2 = Vector2(0,0)
	move_dir.x += float(Input.is_action_pressed("moveright"))
	move_dir.x -= float(Input.is_action_pressed("moveleft"))
	move_dir.y += float(Input.is_action_pressed("moveforward"))
	move_dir.y -= float(Input.is_action_pressed("movebackward"))
	return move_dir
 
func get_try_crouch() -> bool:
	if freeze:
		return false
	return Input.is_action_just_pressed("movedown") 

var last_uncrouch_input: bool = false
func get_try_uncrouch() -> bool:
	if not freeze:
		last_uncrouch_input = Input.is_action_pressed("movedown")
	return last_uncrouch_input

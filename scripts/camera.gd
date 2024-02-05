extends Camera3D
class_name Camera

var mouse_sensitivity: float = 2.0
var pitch_limit: float

const DEG_PITCH_LIMIT: float = 89.99
const OFFSET: Vector3 = Vector3(0, 0.9, 0)

const FOV: float = 90
const DASH_FOV: float = 70

const SNIPER_FOV_MAX: float = 90
const SNIPER_FOV_MIN: float = 25

var old_pos: Vector3 = Vector3.ZERO
var pos_T: float = 1.0
var fov_T: float = 1.0
var blur_T: float = 1.0
var sniper_fov_T: float = 1.0

var mat: ShaderMaterial
@onready var parent: Node3D = $".."

static var has_saved_last_view_angle_before_death: bool = false
var final: Transform3D

@export var death_blur_curve: Curve


@export var max_x := 10.0
@export var max_y := 10.0
@export var max_z := 5.0

var rot_x: float = 0.0
var rot_y: float = 0.0
var rot_z: float = 0.0

@export var noise: FastNoiseLite
@export var noise_speed := 50.0

static var trauma: float = 0.0

var shake_time: float = 0.0

const REDUCTION_RATE: float = 4.0


func add_trauma(trauma_amount : float):
	trauma = clamp(trauma + trauma_amount, 0.0, 1.0)

func get_shake_intensity() -> float:
	return trauma * trauma

func get_noise_from_seed(_seed : int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(shake_time * noise_speed)


func _ready():
	var node: ColorRect = ScreenShader.get_child(0)
	mat = node.material
	mouse_sensitivity = Menu.sensitivity / 1000
	pitch_limit = deg_to_rad(DEG_PITCH_LIMIT)
	
func _set_cam_angle():
	rotation.y = rot_y + max_y * get_shake_intensity() * get_noise_from_seed(1)
	rotation.x = rot_x + max_x * get_shake_intensity() * get_noise_from_seed(0)
	rotation.x = clampf(rotation.x, -pitch_limit, pitch_limit)
	#rotation.z = max_z * get_shake_intensity() * get_noise_from_seed(2)
	
func _process(delta: float) -> void:
	mouse_sensitivity = Menu.sensitivity / 1000
	shake_time += delta
	if not HUD.pause_timer:
		trauma = max(trauma - delta * REDUCTION_RATE, 0.0)
	
	if Controls.is_dead:
		if not has_saved_last_view_angle_before_death:
			rotation.x = 0
			final = Transform3D(global_transform)
			#final.rotation.x = 0
			has_saved_last_view_angle_before_death = true
		
		
		#var origin: Transform3D = last_view_angle_before_death
		#var rotate_transform: Transform3D = Transform3D.IDENTITY
		var amt: float
		if Controls.dead_timer <= 2.0:
			amt = death_blur_curve.sample(Controls.dead_timer)
			amt /= 30.0
			amt += 0.025
		else:
			amt = remap(Controls.dead_timer, 2.0, 4.3, 0.025, 0.35)
			amt = clampf(amt, 0.025, 0.35)
			
		mat.set_shader_parameter("blur_power", amt)
		
		var spin_rate: float = remap(Controls.dead_timer, 0, 1, 0, 1)
		var rot := Transform3D.IDENTITY.rotated(Vector3.UP, Controls.dead_timer * spin_rate)
		var zoom_back: float = remap(ease_out_expo(Controls.dead_timer), 0, 1.0, 0, 10)
		zoom_back = clampf(zoom_back, 0, 10)
		var trans := Transform3D.IDENTITY.translated(Vector3(0, 0, zoom_back))
		fov = clampf(remap(Controls.dead_timer, 0, 5, 159, 10), 10, 159)
		#print(last_view_angle_before_death)
		#transform = last_view_angle_before_death #* translate
		global_transform = final * rot * trans
		return	
	
	fov_T += delta
	pos_T += delta * 10
	blur_T += delta * 7
	
	fov_T = clampf(fov_T, 0, 1)
	pos_T = clampf(pos_T, 0, 1)	
	blur_T = clampf(blur_T, 0, 1)
	
	mat.set_shader_parameter("blur_power", remap(blur_T, 0, 1, 0.03, 0))
	
	_set_cam_angle()
	
	if Controls.get_sniper_scope():
		#sniper_fov_T += delta / 3
		fov = lerpf(SNIPER_FOV_MAX, SNIPER_FOV_MIN, ease_out_expo(Controls.sniper_charge))
	else:
		sniper_fov_T = 0
		fov = lerpf(DASH_FOV, FOV, ease_out_expo(fov_T))
	
	var end: Vector3 = parent.global_transform.origin + OFFSET
	#var mid: Vector3 = old_pos.lerp(end, pos_T)
	global_transform.origin = end
	
func ease_out_expo(x: float) -> float:
	return 1.0 if x == 1.0 else 1.0 - pow(2.0, -10.0 * x)

func dash_cam(pos: Vector3) -> void:
	old_pos = pos
	pos_T = 0
	fov_T = 0
	blur_T = 0
		
func _input(e: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if e is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_rotation((e as InputEventMouseMotion).relative)

func camera_rotation(mouse_delta: Vector2) -> void:
	var sens: float = mouse_sensitivity
	if Controls.get_sniper_scope():
		sens /= 2
	# Horizontal mouse look.
	rot_y -= mouse_delta.x * sens
	# Vertical mouse look.
	rot_x -= mouse_delta.y * sens
	rot_x = clampf(rot_x, -pitch_limit, pitch_limit)

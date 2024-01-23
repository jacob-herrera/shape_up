extends Camera3D
class_name Camera

var mouse_sensitivity: float = 2.0
var pitch_limit: float

const DEG_PITCH_LIMIT: float = 89.99
const OFFSET: Vector3 = Vector3(0, 0.75, 0)

const FOV: float = 90
const DASH_FOV: float = 110

#const LERP: float = 25.0
var old_pos: Vector3 = Vector3.ZERO
var pos_T: float = 1.0
var fov_T: float = 1.0

var mat: ShaderMaterial
@onready var parent: Node3D = $".."

func _ready():
	var node: ColorRect = ScreenShader.get_child(0)
	mat = node.material
	mouse_sensitivity = mouse_sensitivity / 1000
	pitch_limit = deg_to_rad(DEG_PITCH_LIMIT)
	
func _process(delta: float) -> void:
	fov_T = clampf(fov_T + delta * 6, 0, 1)
	fov = lerpf(DASH_FOV, FOV, ease_out_expo(fov_T))
	mat.set_shader_parameter("blur_power", remap(fov_T, 0, 1, 0.05, 0))
	pos_T = clampf(pos_T + delta * 10, 0, 1)
	var end: Vector3 = parent.global_transform.origin + OFFSET
	var mid: Vector3 = old_pos.lerp(end, pos_T)
	global_transform.origin = mid
	
func ease_out_expo(x: float) -> float:
	return 1.0 if x == 1.0 else 1.0 - pow(2.0, -10.0 * x)

func dash_cam(pos: Vector3) -> void:
	old_pos = pos
	pos_T = 0
	fov_T = 0

	
		
func _input(e: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if e is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_rotation((e as InputEventMouseMotion).relative)

func camera_rotation(mouse_delta: Vector2) -> void:
	# Horizontal mouse look.
	rotation.y -= mouse_delta.x * mouse_sensitivity
	# Vertical mouse look.
	rotation.x -= mouse_delta.y * mouse_sensitivity
	rotation.x = clampf(rotation.x, -pitch_limit, pitch_limit)

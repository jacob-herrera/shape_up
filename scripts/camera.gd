extends Camera3D

var mouse_sensitivity: float = 2.0
var pitch_limit: float

const DEG_PITCH_LIMIT: float = 89.99

func _ready():
	mouse_sensitivity = mouse_sensitivity / 1000
	pitch_limit = deg_to_rad(DEG_PITCH_LIMIT)
		
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
	

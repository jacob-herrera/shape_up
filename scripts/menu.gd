extends Control

var enabled: bool = false
var in_settings: bool = false

@onready var main: VBoxContainer = $Margin/Main
@onready var settings: VBoxContainer = $Margin/Settings

func _ready() -> void:
	main.visible = true
	settings.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
	settings.hide()

func reset() -> void:
	%EffectsVolume._on_val_changed(%EffectsVolume.value)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if in_settings:
			_toggle_settings()
		else:
			_toggle_menu()

func _toggle_menu() -> void:
	if Controls.is_dead: return
	if HUD.pause_timer: return
	if enabled:
		hide()
		Engine.time_scale = 1
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		#play_button.grab_focus()
		show()
		Engine.time_scale = 0
		#mouse_filter =
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	enabled = not enabled

func _toggle_settings() -> void:
	if in_settings:
		settings.hide()
		main.show()
	else :
		settings.show()
		main.hide()
	in_settings = not in_settings

func _fullscreen_toggle(full):
	if full == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _settings_back_pressed() -> void:
	_toggle_settings()

func _settings_pressed() -> void:
	_toggle_settings()

func _play_pressed() -> void:
	_toggle_menu()

func _lobby_pressed() -> void:
	SceneManager.goto_lobby()
	_toggle_menu()

func _quit_pressed() -> void:
	get_tree().quit(0)


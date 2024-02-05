extends Control

var enabled: bool = false
var in_settings: bool = false
var in_submenu: bool = false

@onready var main: VBoxContainer = $Margin/Main
@onready var settings: VBoxContainer = $Margin/Settings
@onready var sounds: VBoxContainer = $Margin/Sounds
@onready var graphics: VBoxContainer = $Margin/Graphics
@onready var controls: VBoxContainer = $Margin/Controls

func _ready() -> void:
	main.visible = true
	settings.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
	settings.hide()
	sounds.hide()
	graphics.hide()

func reset() -> void:
	%EffectsVolume._on_val_changed(%EffectsVolume.value)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if in_settings:
			_toggle_settings()
		elif in_submenu:
			_toggle_submenu(settings)
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
		settings.hide()
		sounds.hide()
		graphics.hide()
		controls.hide()
		Engine.time_scale = 0
		#mouse_filter =
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	enabled = not enabled

func _toggle_settings() -> void:
	if in_settings:
		settings.hide()
		main.show()
		sounds.hide()
		graphics.hide()
		controls.hide()
	else:
		settings.show()
		main.hide()
		sounds.hide()
		graphics.hide()
		controls.hide()
	in_settings = not in_settings

func _toggle_submenu(which_menu : VBoxContainer) -> void:
	settings.hide()
	sounds.hide()
	graphics.hide()
	controls.hide()
	which_menu.show()
	in_settings = not in_settings
	in_submenu = not in_submenu

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

func _on_sounds_pressed():
	_toggle_submenu(sounds)

func _on_graphics_pressed():
	_toggle_submenu(graphics)

func _on_controls_pressed():
	_toggle_submenu(controls)

func _submenu_back_pressed():
	_toggle_submenu(settings)

func _on_window_options_item_selected(index):
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

func _on_crt_toggle_toggled(toggled_on):
	HUD.screenshader.visible = toggled_on

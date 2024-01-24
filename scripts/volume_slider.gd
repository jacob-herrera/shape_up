extends HSlider

@export
var bus_name: String

var bus_idx: int

func _ready() -> void:
	bus_idx = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_idx,linear_to_db(value))
	value_changed.connect(_on_val_changed)

func _on_val_changed(val: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx,linear_to_db(val))

extends Label3D

var parent: Node3D

func _ready() -> void:
	parent = get_parent()
	
func _process(_delta: float) -> void:
	text = str(parent.hp)

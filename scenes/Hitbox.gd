extends Node
class_name Hitbox

signal hit

func do_hit(dmg: int) -> void:
	emit_signal("hit", dmg)

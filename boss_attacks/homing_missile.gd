extends Node3D

@export var speed: float
@export var homing_power: float
@export var life_time: float

var time: float = 0.0
	
func _process(delta: float) -> void:
	time += delta
	
	if time >= 20.0:
		queue_free()
		return
	
	#var original
	var target: Vector3 = Character.global_position
	#var dir: Vector3 = global_position.direction_to(target)
	#var angle_to_player: float = global_position.angle_to(target)
	#rotate(dir, angle_to_player)
	if time < life_time:
		var original_basis: Basis = basis
		look_at(target)
		var goal_q = Quaternion(basis)
		var current_q = Quaternion(original_basis)
		
		var t: float = pow(0.5, delta * homing_power)
		#clock_speed = lerpf(target_clock_speed, clock_speed, t)
		var mid = goal_q.slerp(current_q, t)
		transform.basis = Basis(mid)
	global_position += -basis.z * speed * delta
	#rotation = move_toward(rotation, angle_to_player, delta)
	#var dir: Vector3 = global_position.direction_to(target.origin)
	#
	#look_at(target.origin)

func _on_parried() -> void:
	$hurtbox.disabled = true
	queue_free()

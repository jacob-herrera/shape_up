extends Node3D
class_name Boss

@onready var mat: ShaderMaterial = $Visual/Mesh.material_override
@onready var visual: Node3D = $Visual

@onready var growing_circle: PackedScene = preload("res://boss_attacks/growing_circle.tscn")
@onready var missle: PackedScene = preload("res://boss_attacks/homing_missile.tscn")
@onready var chaser: PackedScene = preload("res://boss_attacks/chaser.tscn")
@onready var wall_scene: PackedScene = preload("res://boss_attacks/oct_wall.tscn")

var RNG := RandomNumberGenerator.new()

var alive_time: float = 0.0 
var amt: float = 0.0
var FADE_RATE: float = 4.0

var missile_timer: float = 0.0
var explosion_timer: float = 0.0

var MISSILE_START_RATE: float = 7.0
var MISSILE_END_RATE: float = 4.0

var EXPLOSION_START_RATE: float = 5.0
var EXPLOSION_END_RATE: float = 2.0

var EXPLOSION_START_LIFETIME: float = 10.0
var EXPLOSION_END_LIFETIME: float = 25.0


const SHAKE_STRENGTH: float = 0.5

enum BossAttack {
	EXPLOSION,
	MISSILE
}

enum BossState {
	ORBITING,
	WALLED
}


var state: BossState = BossState.ORBITING

const POS_LERP_SPEED: float = 5.0

#const ATTACK_RATE: float = 2.5
#var attack_cooldown: float = 0.0

const MAX_HEALTH: int = 1500
var health: int = MAX_HEALTH
var spawned_chaser: bool = false

var wall_66: bool = false
var wall_33: bool = false

var wall: Node3D
const WALL_HEALTH_THRESHOLD: int = 200
var wall_health_threshold: int = 0

var boss_phase: int = 1
#var center_pos: Vector3 = Vector3(0.0, 5.25, 0.0) 
var PHASE_ONE_ORIBIT_HEIGHT: float = 5.0
var PHASE_TWO_ORBIT_HEIGHT: float = 7.5
var PHASE_THREE_ORBIT_HEIGHT: float = 10.0

var orbit_height: float = PHASE_ONE_ORIBIT_HEIGHT


func _ready() -> void:
	HUD.boss_health_bar.max_value = MAX_HEALTH
	spawned_chaser = false

func spawn_chaser() -> void:
	if spawned_chaser == true: return

	spawned_chaser = true
	var new: Node3D = chaser.instantiate()
	add_child(new)
	new.global_position = global_position

func try_spawn_wall() -> void:
	if not wall_66 and health <= MAX_HEALTH * 0.6666:
		wall_66 = true
		spawn_wall(2.5, 1.0)
	if not wall_33 and health <= MAX_HEALTH * 0.3333:
		wall_33 = true
		spawn_wall(3.5, 1.5)

	

func spawn_wall(width: float, height: float) -> void:
	wall_health_threshold = WALL_HEALTH_THRESHOLD
	state = BossState.WALLED
	wall = wall_scene.instantiate()
	add_child(wall)
	wall.scale = Vector3(width, height, width)
	wall.global_position = Vector3(0, 0 , 0)
	wall.find_child("WallMesh").material_override.set_shader_parameter("albedo", Color.WHITE)


#func handle_attack(attack: BossAttack) -> void:
	#match attack:
		#BossAttack.EXPLOSION:
			#var new: Node3D = growing_circle.instantiate()
			#add_child(new)
			#var pos: Vector3 = Vector3(randf_range(-62.5, 62.5), 0, randf_range(-62.5, 62.5))
			#new.global_position = pos
		#BossAttack.MISSILE:
			#var new: Node3D = missle.instantiate()
			#add_child(new)
			#new.global_position = global_position

func move_boss(delta: float) -> void:
	var target_pos: Vector3
	
	match state:
		BossState.ORBITING:
			var origin := Transform3D(Basis.IDENTITY, Vector3(0, orbit_height, 0))
			var rot := Transform3D.IDENTITY.rotated(Vector3.UP, alive_time)
			var height: float = sin(alive_time) * 2
			var trans := Transform3D.IDENTITY.translated(Vector3(0, height, 10))
			var final_transform: Transform3D = origin * rot * trans
			target_pos = final_transform.origin
		BossState.WALLED:
			var height: float = sin(alive_time) * 1
			target_pos = Vector3(0, height + orbit_height, 0)
			
	var t: float = pow(0.5, delta * POS_LERP_SPEED)
	global_position = lerp(target_pos, global_position, t)

func _process(delta: float) -> void:
	if Menu.enabled or Controls.is_dead: return 
	
	HUD.update_boss_health(health)
	amt -= delta * FADE_RATE
	#var amt = 
	mat.set_shader_parameter("amt", clampf(amt, 0.0, 1.0))
	var strength: float = remap(clampf(amt, 0.0, 1.0), 0.0, 1.0, 0, SHAKE_STRENGTH)
	var shake_vec := Vector3(RNG.randf_range(-strength, strength), RNG.randf_range(-strength, strength) , RNG.randf_range(-strength, strength))
	visual.global_position = global_position + shake_vec
	
	alive_time += delta
	
	move_boss(delta)
	try_spawn_wall()
	
	missile_timer -= delta
	explosion_timer -= delta
	
	if health <= MAX_HEALTH * 0.5:
		spawn_chaser()
	
	if missile_timer <= 0:
		missile_timer = remap(health, MAX_HEALTH, 0, MISSILE_START_RATE, MISSILE_END_RATE)
		var new: Node3D = missle.instantiate()
		add_child(new)
		new.global_position = global_position
		new.look_at(new.global_position + Vector3.UP)
	
	if explosion_timer <= 0:
		explosion_timer = remap(health, MAX_HEALTH, 0, EXPLOSION_START_RATE, EXPLOSION_END_RATE)
		var new: Node3D = growing_circle.instantiate()
		add_child(new)
		var pos: Vector3 = Vector3.ZERO
		while pos.distance_to(Vector3.ZERO) < 16:
			pos = Vector3(randf_range(-62.5, 62.5), 0, randf_range(-62.5, 62.5))
		new.global_position = pos
		new.max_life_time = remap(health, MAX_HEALTH, 0, EXPLOSION_START_LIFETIME, EXPLOSION_END_LIFETIME)

func _on_hit(dmg: int) -> void:
	health -= dmg
	amt = 1.25
	HUD.shake_health()
	if wall != null:
		var col: float = remap(wall_health_threshold, WALL_HEALTH_THRESHOLD, 0, 1, 0)
		wall.find_child("WallMesh").material_override.set_shader_parameter("albedo", Color(col,col,col))
		wall_health_threshold -= dmg
		if wall_health_threshold <= 0:
			wall.queue_free()
			state = BossState.ORBITING
			boss_phase += 1 
			if boss_phase == 2:
				orbit_height = PHASE_TWO_ORBIT_HEIGHT
			elif boss_phase == 3:
				orbit_height = PHASE_THREE_ORBIT_HEIGHT

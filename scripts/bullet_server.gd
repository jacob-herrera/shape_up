extends Node3D

const MAX_BULLETS: int = 256
const NUM_SHOTGUN_BULLETS: int = 32
const HALF_SHOTGUN_BULLETS: int = 16

const BULLET_GRAV: float = -30.0

const SHOTGUN_BULLET_SPEED: float = 100.0
const AUTO_BULLET_SPEED: float = 200.0

const SNIPER_RANGE: float = 500.0
const AUTO_SPREAD: float = 0.25
const SHOTGUN_SPREAD: float = 8.0


const AUTO_BULLET_DAMAGE: int = 1
const SHOTGUN_BULLET_DAMAGE: int = 1
#const MIN_SNIPER_DAMAGE: int = 64
const MAX_SNIPER_DAMAGE: int = 128

const BULLET_BOUNCES_UNTIL_BOBBING: int = 5
const BULLET_BOUNCES_UNTIL_COLLECTABLE: int = 3
const BULLET_TIME_UNTIL_COLLECTABLE: float = 5.0

const COLLECT_RANGE: float = 5.0
const MAGNETIC_COLLECT_RANGE: float = 10.0
const MAGNETIC_STRENGTH: float = 2500.0
const BOLT_COLLECT_RANGE: float = 10.0

enum BulletState {
	DISABLED,
	PROJECTILE,
	BOBBING,
	MAGNETIZING,
	COLLECTING
}

enum BoltState {
	COLLECTED = 0,
	BOBBING = 1,
	COLLECTING = 2,
}

class Bullet extends Object:
	var state: BulletState
	var velocity: Vector3
	var mesh: MeshInstance3D
	var bounces: int
	var time: float
	var stale: bool
	var dmg: int
	
@export var bb_mesh: PackedScene = preload("res://scenes/bb.tscn")
@export var cone_mesh: PackedScene = preload("res://scenes/cone.tscn")
@export var line_3d: PackedScene = preload("res://scenes/line_3d.tscn")
@export_flags_3d_physics var mask: int

@onready var pop: AudioStreamPlayer = $Pop
@onready var collect_bolt: AudioStreamPlayer = $CollectBolt

var params: PhysicsRayQueryParameters3D
var space: PhysicsDirectSpaceState3D
var line: LineRenderer
var cone: Node3D
var cone_mat: ShaderMaterial
var bullets: Array[Bullet]

var valid_bullets: int = 256
var line_alpha: float = 1.0
#var bolt_in_world: bool = false
var bolt_world_pos: Vector3
var bolt_T: float = 0
var bolt_state: BoltState = BoltState.COLLECTED
var bolt_damage: float = 128.0
var BOLT_DAMAGE_CHARGE_RATE: float = 8.0
#const MAX_BOLT_DA

const MAGNET_TIMEOUT_DURATION: float = 1.0
var magnet_timeout: float = 0.0

func reset() -> void:
	for b: Bullet in bullets:
		b.state = BulletState.DISABLED
		b.mesh.visible = false
	valid_bullets  = MAX_BULLETS
	bolt_state = BoltState.COLLECTED
	line_alpha = 0.0
	bolt_damage = 128.0

func _enter_tree() -> void:
	space = get_world_3d().direct_space_state
	params = PhysicsRayQueryParameters3D.new()
	params.collision_mask = mask
	params.collide_with_areas = true
	bullets = []
	line = line_3d.instantiate()
	add_child(line)
	cone = cone_mesh.instantiate()
	add_child(cone)
	cone_mat = cone.get_child(0).material_override
	
	for i in MAX_BULLETS:
		var mesh: MeshInstance3D = bb_mesh.instantiate() as MeshInstance3D
		add_child(mesh)
		mesh.visible = false
		mesh.global_transform.origin = Vector3(0, 2, 0)
		var bullet: Bullet = Bullet.new()
		bullet.state = BulletState.DISABLED
		bullet.mesh = mesh
		bullet.velocity = Vector3.ZERO
		bullet.bounces = 0
		bullets.push_back(bullet)
		
func _ready() -> void:
	line.set_camera(get_viewport().get_camera_3d())

func _exit_tree() -> void:
	line.queue_free()
	cone.queue_free()
	for bullet: Bullet in bullets:
		bullet.free()

func _process_bolt(delta: float) -> void:
	match bolt_state:
		BoltState.BOBBING:
			var dist_to_bolt: float = bolt_world_pos.distance_to(Character.global_position)
			if dist_to_bolt <= BOLT_COLLECT_RANGE:
				bolt_state = BoltState.COLLECTING
				bolt_T = 0.0
				return
			bolt_T += delta
			var offset: float = sin(bolt_T * 5.0) / 4.0
			cone.global_transform.origin = bolt_world_pos + Vector3(0, offset, 0)
			cone.rotation.y = bolt_T * 2.0
		BoltState.COLLECTING:
			bolt_T += delta * 2.0
			var target: Vector3 = Character.global_position + Vector3(0, -2, 0)
			if bolt_T >= 0.75:
				bolt_state = BoltState.COLLECTED
				collect_bolt.play()
			cone_mat.set_shader_parameter("alpha", 1-bolt_T)
			cone.global_position = lerp(cone.global_position, target, bolt_T) 
		BoltState.COLLECTED:
			bolt_damage += delta * BOLT_DAMAGE_CHARGE_RATE
			bolt_damage = clampf(bolt_damage, 0, MAX_SNIPER_DAMAGE)
			
	cone.visible = bolt_state != BoltState.COLLECTED

func _try_collect_bullet(delta: float, bullet: Bullet, target: Vector3) -> void:
	var dir: Vector3 = target - bullet.mesh.global_transform.origin
	var height_diff: float = absf(target.y - bullet.mesh.global_transform.origin.y)
	var dist: float = dir.length()
	var flat_dist: float = Vector3(target.x, 0, target.z).distance_to(Vector3(bullet.mesh.global_transform.origin.x, 0, bullet.mesh.global_transform.origin.z))
	var collect_range: float = MAGNETIC_COLLECT_RANGE if magnet_timeout > 0 else COLLECT_RANGE
	# Cylinder hitbox
	if flat_dist < collect_range and height_diff <= collect_range:
		bullet.state = BulletState.COLLECTING
		bullet.time = 0
	elif magnet_timeout <= 0:
		if bullet.state == BulletState.BOBBING:
			var flat_bullet_pos: Vector3 = bullet.mesh.global_transform.origin
			flat_bullet_pos.y = 0
			var strength: float = MAGNETIC_STRENGTH / (dist * dist)
			flat_bullet_pos += dir.normalized() * strength * delta
			bullet.mesh.global_transform.origin = Vector3(flat_bullet_pos.x, bullet.mesh.global_transform.origin.y, flat_bullet_pos.z)
		elif bullet.state == BulletState.PROJECTILE:
			var strength: float = MAGNETIC_STRENGTH / (dist * dist)
			bullet.mesh.global_transform.origin += dir.normalized() * strength * delta
		
func _process(delta: float) -> void:
	if Menu.enabled: return
	
	magnet_timeout -= delta
	line_alpha -= delta
	line_alpha = clampf(line_alpha, 0.0, 1.0)
	line.material.set_shader_parameter("alpha", line_alpha)
	

	
	
	
	var char_pos: Vector3 = Character.global_transform.origin
	

		
	_process_bolt(delta)
	
	for bullet: Bullet in bullets:
		match bullet.state:
			BulletState.PROJECTILE:
				bullet.time += delta
				bullet.velocity += Vector3(0, BULLET_GRAV * delta, 0)
				var start: Vector3 = bullet.mesh.global_transform.origin
				var end: Vector3 = start + (bullet.velocity * delta)
				if start.is_equal_approx(end): continue
				params.from = start
				params.to = end
				var result: Dictionary = space.intersect_ray(params)
				if not result.is_empty():
					var did_hit: bool = false
					
					if not bullet.stale:
						var hitbox: Hitbox = result.collider.find_child("Hitbox", false) as Hitbox
						if hitbox != null:
							hitbox.do_hit(bullet.dmg)
							did_hit = true
					
					var pass_through: bool = Vector3.DOWN.is_equal_approx(result.normal) and did_hit
					
					if not pass_through:
						bullet.velocity = bullet.velocity.bounce(result.normal)
						bullet.velocity = bullet.velocity.normalized() * bullet.velocity.length() / 3
						if bullet.bounces > 0 and Vector3.UP.is_equal_approx(result.normal):
							bullet.bounces = BULLET_BOUNCES_UNTIL_COLLECTABLE
						else:
							bullet.bounces += 1
						if bullet.bounces >= BULLET_BOUNCES_UNTIL_COLLECTABLE:
							bullet.stale = true
						var dir: Vector3 = (end - start).normalized() / 1000.0
						bullet.mesh.global_transform.origin = result.position - dir
					else:
						bullet.stale = true
						bullet.mesh.global_transform.origin = end
		

						
				else:
					bullet.mesh.global_transform.origin = end
					
				if bullet.velocity.length() <= 1.0:
					bullet.state = BulletState.BOBBING
					bullet.mesh.global_transform.origin.y = 0
					bullet.time = -3 + randf()
				elif bullet.bounces >= BULLET_BOUNCES_UNTIL_COLLECTABLE \
					or bullet.time >= BULLET_TIME_UNTIL_COLLECTABLE:
					_try_collect_bullet(delta, bullet, char_pos)
					
			BulletState.BOBBING:
				bullet.time += delta * 2.0
				_try_collect_bullet(delta, bullet, char_pos)
				bullet.mesh.global_transform.origin.y = bob_ease(bullet.time)
			BulletState.COLLECTING:
				bullet.time += delta
				var t: float = remap(bullet.time, 0.0, 0.25, 0.0, 1.0)
				bullet.mesh.global_transform.origin = lerp(bullet.mesh.global_transform.origin, char_pos - Vector3(0, 0.5, 0), t)
				if t >= 0.6:
					bullet.state = BulletState.DISABLED
					bullet.mesh.visible = false
					valid_bullets += 1
					pop.play()
	
func bob_ease(bob: float) -> float:
	if bob > 0:
		bob = sin(bob) / 4.0
		return bob + 0.5
	else:
		bob = clampf(bob, -1, 0)
		bob = remap(bob, -1, 0, 0.05, 0.5	)
		return bob
	
func _fire_bullet(pos: Vector3, dir: Vector3, speed: float, dmg: int) -> void:
	for bullet: Bullet in bullets:
		if bullet.state == BulletState.DISABLED:
			bullet.state = BulletState.PROJECTILE
			bullet.mesh.visible = true 
			bullet.mesh.global_transform.origin = pos
			bullet.velocity = dir * speed
			bullet.bounces = 0
			bullet.stale = false
			bullet.time = 0
			bullet.dmg = dmg
			valid_bullets -= 1
			break
			
func fire_auto(pos: Vector3, dir: Vector3) -> bool:
	if valid_bullets == 0: return false
	magnet_timeout = MAGNET_TIMEOUT_DURATION
	var spread: Vector3 = Math.random_unit_vector_in_cone(dir, AUTO_SPREAD)
	_fire_bullet(pos, spread, AUTO_BULLET_SPEED, AUTO_BULLET_DAMAGE)
	return true
			
func fire_shotgun(pos: Vector3, dir: Vector3) -> int:
	if valid_bullets == 0: return 0
	magnet_timeout = MAGNET_TIMEOUT_DURATION
	var shots = clampi(valid_bullets, 1, NUM_SHOTGUN_BULLETS)
	for i in shots:
		var spread: Vector3 = Math.random_unit_vector_in_cone(dir, SHOTGUN_SPREAD)
		_fire_bullet(pos, spread, SHOTGUN_BULLET_SPEED, SHOTGUN_BULLET_DAMAGE)
	if shots >= HALF_SHOTGUN_BULLETS:
		return 2
	else:
		return 1

func fire_sniper(pos: Vector3, dir: Vector3) -> void:
	params.from = pos
	params.to = pos + dir * SNIPER_RANGE
	var result: Dictionary = space.intersect_ray(params)
	if result.is_empty(): return
	line.points[0] = params.from
	line.points[1] = result.position
	line_alpha = 1
	bolt_world_pos = Vector3(result.position.x, 0, result.position.z)
	cone.global_position = bolt_world_pos
	bolt_state = BoltState.BOBBING
	cone_mat.set_shader_parameter("alpha", 1.0)
	
	var hitbox: Hitbox = result.collider.find_child("Hitbox", false) as Hitbox
	if hitbox != null:
		var dmg: int = bolt_damage#remap(Controls.sniper_charge, 0.0, 1.0, 0, MAX_SNIPER_DAMAGE) as int
		hitbox.do_hit(dmg)
		bolt_damage = 0


extends Node3D

@export var sprite3Ds: Array[Sprite3D]
@onready var original_droplet: MeshInstance3D = $droplet

const N_PARTICLES = 64
var particles: Array[Droplet]

var PARTICLE_SPEED_MAX: float = 5.0
var PARTICLE_SPEED_MIN: float = 2.0
var PARTICLE_GRAVITY: float = -2.0
var PARTICLE_SPREAD_DEG: float = 45.0

var fps: float = 6

class Droplet extends Object:
	var mesh: MeshInstance3D
	var inital_velocity: Vector3

func _ready() -> void:
	#particles.push_back(droplet)
	for i in N_PARTICLES:
		var clone: MeshInstance3D = original_droplet.duplicate(0)
		add_child(clone)
		var drop: Droplet = Droplet.new()
		drop.mesh = clone
		var speed: float = randf_range(PARTICLE_SPEED_MIN, PARTICLE_SPEED_MAX)
		drop.inital_velocity = Math.random_unit_vector_in_cone(Vector3.UP, PARTICLE_SPREAD_DEG) * speed
		particles.push_back(drop)
	
	original_droplet.queue_free()

func _process(delta: float) -> void:
	#if go:
	visible = Controls.dead_timer > 0
	var time = Controls.dead_timer - 0.1
	time = maxf(0.0, time)
	for s: Sprite3D in sprite3Ds:
		var target: int = time * fps
		target = clampi(target, 0, s.hframes * s.vframes - 1)
		s.frame = target
	var origin: Vector3 = get_parent().global_position
	for droplet: Droplet in particles:
		var motion: Vector3 = droplet.inital_velocity * time
		var gravity_drop: Vector3 = Vector3(0, PARTICLE_GRAVITY, 0) * time * time
		droplet.mesh.global_position = origin + motion + gravity_drop

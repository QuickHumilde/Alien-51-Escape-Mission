extends Node2D
class_name LaserBeam

@onready var line : Line2D = $Line2D
@onready var ray_cast : RayCast2D = $RayCast2D
@export var max_length : float = 500.0
@export var damage_per_second : float = 1.5

var laser_owner = ""
var firing : bool = true

func _ready():
	line.visible = true
	ray_cast.enabled = true

	var mat : ShaderMaterial = ShaderMaterial.new()
	mat.shader = preload("res://shaders/laser_shader.gdshader")
	mat.set_shader_parameter("tint_color", Color("ff6eb4"))
	line.material = mat

func setup(owner_node):
	laser_owner = owner_node

func _process(delta):
	if not firing:
		return

	if owner:
		global_position = owner.global_position
		global_rotation = owner.global_rotation

	var direction : Vector2 = Vector2.RIGHT
	ray_cast.target_position = direction * max_length
	ray_cast.force_raycast_update()
	var hit_pos_global : Vector2

	if ray_cast.is_colliding():
		hit_pos_global = ray_cast.get_collision_point()
	else:
		hit_pos_global = global_position + global_transform.x * max_length

	var hit_pos_local : Vector2 = to_local(hit_pos_global)
	var jitter = Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
	line.points = [
		Vector2.ZERO,
		hit_pos_local + jitter
	]

	if ray_cast.is_colliding():
		var collider : Object = ray_cast.get_collider()
		if collider.is_in_group("enemy"):
			var enemy_collider = collider.get_parent()
			if enemy_collider.has_method("take_damage"):
				enemy_collider.take_damage(damage_per_second * delta)
				
	$ImpactParticles.global_position = hit_pos_global
	$ImpactParticles.emitting = ray_cast.is_colliding()

func stop():
	firing = false
	queue_free()

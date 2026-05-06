extends Node2D
class_name LaserBeam

@onready var line : Line2D = $Line2D
@onready var ray_cast : RayCast2D = $RayCast2D
@export var max_length : float = 0.0
@export var damage_per_second : float = 1.0
@export var knockback_force : float = 0.0

var laser_owner = ""
var barrel = null
var firing : bool = true

func _ready():
	line.visible = true
	ray_cast.enabled = true

	var mat : ShaderMaterial = ShaderMaterial.new()
	mat.shader = preload("res://shaders/laser_shader.gdshader")
	mat.set_shader_parameter("tint_color", Color("ff82f8"))
	line.material = mat

func setup(owner_node, barrel_node = null):
	laser_owner = owner_node
	barrel = barrel_node

func get_valid_laser_hit():
	var space_state = get_world_2d().direct_space_state
	var origin = global_position
	var direction = global_transform.x.normalized()
	var remaining_length = max_length
	var exclude = []
	while remaining_length > 0:
		var to = origin + direction * remaining_length
		var params = PhysicsRayQueryParameters2D.create(origin, to)
		params.collide_with_areas = ray_cast.collide_with_areas
		params.collision_mask = ray_cast.collision_mask
		params.exclude = exclude
		var result = space_state.intersect_ray(params)
		if result:
			var collider = result["collider"]
			if collider and collider.is_in_group("laser_ignore"):
				exclude.append(collider)
				origin = result["position"] + direction * 0.1
				remaining_length = max_length - (origin - global_position).length()
				continue
			else:
				return result
		break
	return null

func _process(delta):
	if not firing:
		return

	if barrel != null:
		global_position = barrel.global_position
		global_rotation = barrel.global_rotation

	var _direction : Vector2 = Vector2.RIGHT
	var hit_result = get_valid_laser_hit()
	var hit_pos_global : Vector2

	if hit_result:
		hit_pos_global = hit_result.position
	else:
		hit_pos_global = global_position + global_transform.x * max_length

	var hit_pos_local : Vector2 = to_local(hit_pos_global)
	var jitter = Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5))
	line.points = [
		Vector2.ZERO,
		hit_pos_local + jitter
	]

	if hit_result:
		var collider : Object = hit_result.collider
		if collider.is_in_group("enemy"):
			var enemy_collider = collider.get_parent()
			if enemy_collider.has_method("take_damage"):
				enemy_collider.take_damage(damage_per_second * delta)
			if enemy_collider.has_method("apply_knockback"):
				enemy_collider.apply_knockback(hit_pos_local, knockback_force * delta)
				
	$ImpactParticles.global_position = hit_pos_global
	$ImpactParticles.emitting = hit_result != null

func stop():
	firing = false
	queue_free()

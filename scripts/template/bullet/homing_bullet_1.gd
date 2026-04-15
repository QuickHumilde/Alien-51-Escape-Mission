extends Bullet
class_name HomingBullet

@export var turn_speed: float = 4.0
@export var homing_radius: float = 70.0
@export var target_group: String = "enemy"
@onready var homing_area: Area2D = $HomingArea
@onready var homing_area_collision: CollisionShape2D = $HomingArea/CollisionShape2D


var target: Node2D = null

func init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_bullet_owner, extras: Dictionary = {}) -> void:
	super.init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_bullet_owner, extras)
	if extras.has("turn_speed"):
		turn_speed = extras.turn_speed
	if extras.has("homing_radius"):
		homing_radius = extras.homing_radius
		homing_area_collision.shape.radius = homing_radius

func _ready() -> void:
	super._ready()
	homing_area.body_entered.connect(_on_homing_area_enter)
	var bodies = homing_area.get_overlapping_bodies()
	var best_target: Node2D = null
	var first_time: bool = true
	
	for body in bodies:
		print(body)
		if target == null and body.is_in_group(target_group):
			if first_time:
				best_target=body
			else:
				var distance = global_position.distance_to(body.global_position)
				if distance < global_position.distance_to(best_target.global_position):
					best_target = body
	if best_target != null:
		target = best_target

func _process(delta: float):
	if get_tree().paused:
		return

	if target != null:
		if not is_instance_valid(target) or not homing_area.get_overlapping_bodies().has(target):
			target = null

	if target != null:
		var desired := (target.global_position - global_position).normalized()
		bullet_direction = bullet_direction.slerp(desired, clamp(turn_speed * delta, 0.0, 1.0)).normalized()

	global_position += bullet_direction * speed * delta

	rotation_degrees += speed_rotation * delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()

	for area in get_overlapping_areas():
		_on_hitbox_enter(area)
	for body in get_overlapping_bodies():
		_on_hitbox_enter(body)


func _on_homing_area_enter(body):
	if target == null and body.is_in_group(target_group):
		target = body

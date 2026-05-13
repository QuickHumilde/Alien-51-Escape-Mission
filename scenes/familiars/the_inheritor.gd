extends Node2D
class_name BasicFamiliar

@export var orbit_radius: float = 15.0
@export var orbit_speed: float = 0.5
@export var follow_lerp: float = 12.0
@export var spawn_offset: float = 10.0

var _player: CharacterBody2D = null
var _t: float = 0.0
var _shoot_t: float = 0.0

var bullet_scene: PackedScene = null
var shoot_interval: float = 1.5
var target_range: float = 100.0
var bullet_damage: float = 1.0
var bullet_speed: float = 200.0
var bullet_lifetime: float = 0.75
var bullet_knockback: float = 120.0

func init(player: CharacterBody2D) -> void:
	_player = player

func configure(data: Dictionary) -> void:
	if data.has("bullet_scene"): bullet_scene = data["bullet_scene"]
	if data.has("shoot_interval"): shoot_interval = float(data["shoot_interval"])
	if data.has("target_range"): target_range = float(data["target_range"])
	if data.has("bullet_damage"): bullet_damage = float(data["bullet_damage"])
	if data.has("bullet_speed"): bullet_speed = float(data["bullet_speed"])
	if data.has("bullet_lifetime"): bullet_lifetime = float(data["bullet_lifetime"])
	if data.has("bullet_knockback"): bullet_knockback = float(data["bullet_knockback"])

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return

	_t += delta
	var orbit := Vector2(cos(_t * orbit_speed), sin(_t * orbit_speed)) * orbit_radius
	var desired := _player.global_position + orbit
	global_position = global_position.lerp(desired, clamp(follow_lerp * delta, 0.0, 1.0))

	_shoot_t -= delta
	if _shoot_t <= 0.0:
		_shoot_t = shoot_interval
		_try_shoot()

func _try_shoot() -> void:
	if bullet_scene == null:
		return

	var enemy := _find_target()
	if enemy == null:
		return

	var to_enemy = enemy.global_position - global_position
	if to_enemy.length_squared() < 0.0001:
		return

	var dir = to_enemy.normalized()

	var b = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)

	var spawn_pos = global_position + dir * spawn_offset

	if b.has_method("init"):
		b.init(
			dir,
			spawn_pos,
			bullet_damage,
			bullet_knockback,
			bullet_lifetime,
			bullet_speed,
			"player"
		)
	else:
		b.global_position = spawn_pos

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_d2 := target_range * target_range

	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Node2D
		if e == null or not is_instance_valid(e):
			continue
		var d2 := global_position.distance_squared_to(e.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = e

	return best

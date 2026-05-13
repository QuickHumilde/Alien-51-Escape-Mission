extends Area2D
class_name DeodorantScene

@export var damage_per_second: float = 0.75
@export var knockback_force_per_second: float = 0.0

@export var only_damage_group: String = "enemy"

@export var debug_draw: bool = true
@export var odor_colors: Array[Color] = [
	Color(0.506, 0.584, 0.0, 0.431),
	Color(0.486, 0.498, 0.024, 0.431),
	Color(0.424, 0.498, 0.286, 0.431)  
]

@export var debug_width: float = 1.5

@onready var col_shape: CollisionShape2D = $CollisionShape2D

var _targets: Array[Node] = []
var _anim_time: float = 0.0

func _ready() -> void:
	monitoring = true
	monitorable = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	queue_redraw()

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()
	
	if _targets.is_empty():
		return

	var unique_enemies: Dictionary = {}

	for i in range(_targets.size() - 1, -1, -1):
		var t := _targets[i]
		if t == null or not is_instance_valid(t):
			_targets.remove_at(i)
			continue

		var enemy := _get_damageable_owner(t)
		if enemy != null:
			unique_enemies[enemy] = true

	var dmg := damage_per_second * delta
	for enemy in unique_enemies.keys():
		if enemy.has_method("take_damage"):
			enemy.take_damage(dmg)

		if knockback_force_per_second > 0.0 and enemy.has_method("apply_knockback"):
			var dir := ((enemy as Node2D).global_position - global_position).normalized()
			enemy.apply_knockback(dir, knockback_force_per_second * delta)

func _on_body_entered(body: Node) -> void:
	_try_add_target(body)

func _on_body_exited(body: Node) -> void:
	_targets.erase(body)

func _on_area_entered(area: Area2D) -> void:
	_try_add_target(area)

func _on_area_exited(area: Area2D) -> void:
	_targets.erase(area)

func _try_add_target(n: Node) -> void:
	if n == null:
		return
	if not _targets.has(n):
		_targets.append(n)

func _get_damageable_owner(n: Node) -> Node:
	var cur: Node = n
	while cur != null:
		if only_damage_group != "" and cur.is_in_group(only_damage_group):
			return cur
		if cur.has_method("take_damage"):
			return cur
		cur = cur.get_parent()
	return null

func _draw() -> void:
	if not debug_draw:
		return
	if col_shape == null or col_shape.shape == null:
		return

	var s := col_shape.shape as CircleShape2D
	var offset := col_shape.position
	var num = odor_colors.size()
	var t = _anim_time * 0.5 
	var idx1 = int(floor(t)) % num
	var idx2 = (idx1 + 1) % num
	var weight = t - floor(t)
	var color = odor_colors[idx1].lerp(odor_colors[idx2], weight)

	var base_radius = s.radius
	var points = []
	var detail = 42
	for i in detail:
		var ang = (TAU / detail) * i
		var r_osc = base_radius * (1.0 + 0.07 * sin(ang * 3.0 + _anim_time * 1.3 + sin(ang * 2.1 + _anim_time)))
		var point = offset + Vector2.RIGHT.rotated(ang) * r_osc
		points.append(point)
	draw_colored_polygon(points, color)

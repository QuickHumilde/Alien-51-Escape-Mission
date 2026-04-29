@abstract
extends Area2D
class_name Bullet

var speed: float = 0.0
var damage: float = 0.0
var knockback_force : float = 0.0
var lifetime: float = 5.0
var bullet_direction = Vector2.RIGHT
var time_left: float
var modifiers: Array = []
var bullet_owner : String = "-"
var speed_rotation: float = 0.0

var hit_enemies: Dictionary = {}

func _ready():
	self.body_entered.connect(_on_hitbox_enter)
	self.area_entered.connect(_on_hitbox_enter)
	
	time_left = lifetime

func init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_bullet_owner, _extras: Dictionary = {}) -> void:
	self.global_position = new_position
	self.bullet_direction = new_forward
	self.damage = new_damage
	self.knockback_force = new_knockback_force
	self.lifetime = new_lifetime
	self.speed = new_speed
	self.bullet_owner = new_bullet_owner

func _process(delta: float):
	if get_tree().paused:
		return
	global_position += bullet_direction * speed * delta
	rotation_degrees += speed_rotation * delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
	for area in get_overlapping_areas():
		_on_hitbox_enter(area)
	for body in get_overlapping_bodies():
		_on_hitbox_enter(body)
  
func _on_hitbox_enter(area):
	if area.is_in_group("obstacle"):
		_against_obstacle(area)
		
	if area.is_in_group("wall"):
		_against_wall()
		
	if area.is_in_group("enemy") and bullet_owner != "enemy":
		var enemy_node = area.get_parent()

		if hit_enemies.has(enemy_node):
			return
		hit_enemies[enemy_node] = true

		if is_instance_valid(enemy_node):
			if not enemy_node.is_connected("tree_exited", Callable(self, "_on_enemy_tree_exited")):
				enemy_node.connect("tree_exited", Callable(self, "_on_enemy_tree_exited").bind(enemy_node))

		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)
		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)
		_against_enemy(area)
		
	if area.is_in_group("player") and bullet_owner != "player":
		var player_node = area.get_parent()
		if player_node.has_method("apply_knockback"):
			var knockback_direction = (player_node.global_position - global_position).normalized()
			player_node.apply_knockback(knockback_direction, knockback_force)
		if player_node.has_method("take_damage"):
			player_node.take_damage(damage)
		_against_enemy(area)

func _on_enemy_tree_exited(enemy_node):
	if hit_enemies.has(enemy_node):
		hit_enemies.erase(enemy_node)

func _against_obstacle(area):
	if area.has_method("receive_hit"):
		area.receive_hit()
	destroy_bullet()
		
func _against_wall():
	destroy_bullet()
		
func _against_enemy(_area):
	if not modifiers.has("piercing"):
		destroy_bullet()

func change_direction(new_direction: Vector2, new_owner = ""):
	if new_owner != "":
		bullet_owner = new_owner
	bullet_direction = new_direction

func destroy_bullet():
	queue_free()

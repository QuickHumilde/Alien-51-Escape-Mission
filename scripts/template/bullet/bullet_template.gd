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

@onready var background_tilemap = get_tree().get_current_scene().get_node("Background")
@onready var foreground_tilemap = get_tree().get_current_scene().get_node("Foreground")

func _ready():
	self.body_entered.connect(_on_hitbox_enter)
	self.area_entered.connect(_on_hitbox_enter)
	
	time_left = lifetime
	
func _process(delta: float):
	if get_tree().paused:
		return
	global_position -= bullet_direction * speed * delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
  
func _on_hitbox_enter(area):
	if area.is_in_group("obstacle"):
		destroy_bullet()
		
	if area.is_in_group("wall"):
		destroy_bullet()
		
	if area.is_in_group("enemy"):
		var enemy_node = area.get_parent()
		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)
		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)
		_against_enemy()
		
func _against_obstacle():
	queue_free()
		
func _against_wall():
	queue_free()
		
func _against_enemy():
	if not modifiers.has("piercing"):
		queue_free()

func destroy_bullet():
	queue_free()

@abstract
extends Area2D
class_name Bullet

var speed: float = 0.0
var damage: float = 0.0
var knockback_force = 0.0
var lifetime: float = 5.0
var bullet_direction = Vector2.RIGHT
@onready var background_tilemap = get_tree().get_current_scene().get_node("Background")
@onready var foreground_tilemap = get_tree().get_current_scene().get_node("Foreground")

func _ready():
	self.body_entered.connect(_on_hitbox_enter)
	self.area_entered.connect(_on_hitbox_enter)
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	
func _process(delta: float):
	global_position -= bullet_direction * speed * delta

func _on_hitbox_enter(area):
	if area.is_in_group("enemy") or area.is_in_group("walls"):
		var enemy_node = area.get_parent()
		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)
		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)
	queue_free()

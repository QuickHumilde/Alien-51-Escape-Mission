@abstract
extends CharacterBody2D
class_name Enemy

@export var id : int
@export var speed : float = 50.0
@export var health : float = 3.0
@export var contact_damage: float = 0.0
@onready var player: CharacterBody2D = get_tree().current_scene.get_node("Player")
var knockback: Vector2
@export var knockback_force : float = 0.0
var knockback_time : float = 0.0
var knockback_resistance : float =0.0

func apply_knockback(dir: Vector2, force: float = 500.0, duration: float = 0.2):
	if knockback_resistance < force:
		knockback = dir * (force - knockback_resistance)
		knockback_time = duration

@abstract func take_damage(damage : float)

@abstract func die()

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		do_damage(body)
		


func do_damage(body):
	var knockback_direction = (body.global_position - global_position).normalized()
	if body.is_in_group("player"):
		if is_player_damagable(body):
			body.apply_knockback(knockback_direction, knockback_force)
			body.take_damage(contact_damage)

func _get_detector():
	$Detector.body_entered.connect(_on_area_2d_body_entered)
  
func get_damage():
	return contact_damage

func is_player_damagable(body: Character):
	return body.is_player_damagable()

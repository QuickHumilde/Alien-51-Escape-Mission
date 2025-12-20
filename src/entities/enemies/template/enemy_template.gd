@abstract
extends CharacterBody2D
class_name Enemy

@export var id : int
@export var speed := 50.0
@export var health := 3.0
@onready var player: CharacterBody2D = get_tree().current_scene.get_node("Player")
var knockback: Vector2
var knockback_force := 0.0
var knockback_time := 0.0

func apply_knockback(dir: Vector2, force: float = 500.0, duration: float = 0.2):
	knockback = dir * force
	knockback_time = duration

@abstract func take_damage(damage : float)

@abstract func die()

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		var knockback_direction = (body.global_position - global_position).normalized()
		body.movement.apply_knockback(knockback_direction, knockback_force)

func get_detector():
	$Detector.body_entered.connect(_on_area_2d_body_entered)

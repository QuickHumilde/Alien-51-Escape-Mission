extends Node
class_name CharacterStats

var sprite: AnimatedSprite2D
@export var max_health: int = 5
@export var health: int = 5
@export var speed: float = 100.0
@export var size: float = 1.0

func take_damage(amount: int):
	sprite.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1,1,1)
	health -= amount
	if health <= 0:
		queue_free()

func heal(amount: int, overheal: bool):
	print(overheal)
	if(!overheal):
		health = min(health + amount, max_health)
	else:
		health+=amount

func increase_max_health(amount: int):
	max_health += amount
	health = max_health

func modify_speed(amount: float):
	speed += amount

func modify_size(amount: float):
	size += amount
	get_parent().get_parent().sprite.scale = Vector2.ONE * size

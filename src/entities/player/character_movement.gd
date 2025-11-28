extends Node
class_name CharacterMovement

var direction: Vector2 = Vector2.ZERO
var knockback: Vector2

func update(_delta, character):
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	character.velocity = direction * character.stats.speed

func apply_knockback(direction: Vector2, force: float):
	knockback= direction * force
	

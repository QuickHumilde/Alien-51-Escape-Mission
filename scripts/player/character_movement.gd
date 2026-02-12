extends Node
class_name CharacterMovement

var direction: Vector2 = Vector2.ZERO
var knockback: Vector2
var character: CharacterBody2D
static var knockback_time: float = 0.0

func init(player: CharacterBody2D) -> void:
	character=player

func update(delta, charac):
	if knockback_time > 0:
		knockback_time -= delta
		charac.velocity = knockback
		return
	
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	direction = direction.normalized()
	charac.velocity = direction * charac.stats.get_speed()

func apply_knockback(dir: Vector2, force: float, duration: float = 0.2):
	knockback = dir * force
	knockback_time = duration

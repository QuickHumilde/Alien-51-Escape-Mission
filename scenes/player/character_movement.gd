extends Node
class_name CharacterMovement

var direction: Vector2 = Vector2.ZERO
var knockback: Vector2
var character: CharacterBody2D
var current_speed : float = 0.0
var knockback_time: float = 0.0
var speed_override: float = -1.0

func init(player: CharacterBody2D) -> void:
	character = player
	current_speed = character.stats.get_speed()

func update(delta, charac):
	current_speed = get_current_speed()

	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	direction = direction.normalized()
	
	var move_velocity = direction * current_speed
	
	if knockback_time > 0:
		knockback_time -= delta
		charac.velocity = move_velocity + knockback
		knockback = knockback.move_toward(Vector2.ZERO,(knockback.length() / max(knockback_time, 0.01)) * delta)
	else:
		knockback = Vector2.ZERO
		charac.velocity = move_velocity

func apply_knockback(dir: Vector2, force: float, duration: float = 0.2):
	knockback = dir * force
	knockback_time = duration

func get_current_speed() -> float:
	if speed_override >= 0.0:
		return speed_override
	return character.stats.get_speed()

func override_speed(value: float) -> void:
	speed_override = value

func clear_override_speed() -> void:
	speed_override = -1.0

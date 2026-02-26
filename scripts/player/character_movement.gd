extends Node
class_name CharacterMovement

var direction: Vector2 = Vector2.ZERO
var knockback: Vector2
var character: CharacterBody2D
var current_speed : float = 0.0
static var knockback_time: float = 0.0
var test:=false

func init(player: CharacterBody2D) -> void:
	character=player
	current_speed = character.stats.get_speed()

func update(delta, charac):
	if knockback_time > 0:
		knockback_time -= delta
		charac.velocity = knockback
		return
	
	current_speed = character.stats.get_speed()
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	direction = direction.normalized()
	charac.velocity = direction * current_speed
	
	if Input.get_action_strength("tests"):
		if test:
			print("tests_off")
			test=false
		else:
			print("tests_on")
			test=true

func apply_knockback(dir: Vector2, force: float, duration: float = 0.2):
	knockback = dir * force
	knockback_time = duration

extends Node
class_name CharacterAnimation

var sprite: AnimatedSprite2D
var cardinal_direction: Vector2 = Vector2.DOWN
var state: String = "idle"
var damage_timer: Timer
var is_flying: bool = false

func init(player_sprite: AnimatedSprite2D, timer: Timer):
	sprite=player_sprite
	damage_timer=timer

func update(character):
	if set_state(character) or set_direction(character):
		sprite.play(state + "_" + anim_direction())

func set_direction(character) -> bool:
	var new_direction: Vector2 = cardinal_direction
	if character.velocity == Vector2.ZERO:
		return false
	if character.velocity.y == 0:
		new_direction = Vector2.LEFT if character.velocity.x < 0 else Vector2.RIGHT
	elif character.velocity.x == 0:
		new_direction = Vector2.UP if character.velocity.y < 0 else Vector2.DOWN
	if new_direction == cardinal_direction:
		return false
	cardinal_direction = new_direction
	character.sprite.flip_h = (cardinal_direction == Vector2.LEFT)
	return true

func set_state(character) -> bool:
	var new_state: String
	if is_flying:
		new_state = "fly"
	else:
		new_state = "idle" if character.velocity == Vector2.ZERO else "walk"
	if new_state == state:
		return false
	state = new_state
	return true

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

func player_taking_damage():
	if !Signals.player_is_dead:
		sprite.modulate = Color(1, 0, 0, 1)
		damage_timer.start()
		
		while (!damage_timer.is_stopped()):
			await get_tree().create_timer(0.1).timeout
			sprite.modulate = Color(0.431, 0.0, 0.0, 0.0)
			await get_tree().create_timer(0.1).timeout
			sprite.modulate = Color(1,1,1)
		
		damage_timer.stop()

func player_dying():
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.play("dying")
	await sprite.animation_finished
	Signals.show_death_menu.emit()
	sprite.process_mode = Node.PROCESS_MODE_INHERIT

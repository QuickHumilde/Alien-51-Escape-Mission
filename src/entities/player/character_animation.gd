extends Node
class_name CharacterAnimation

var cardinal_direction: Vector2 = Vector2.DOWN
var state: String = "idle"

func update(character):
	if set_state(character) or set_direction(character):
		character.sprite.play(state + "_" + anim_direction())

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
	character.sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func set_state(character) -> bool:
	var new_state: String = "idle" if character.velocity == Vector2.ZERO else "walk"
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

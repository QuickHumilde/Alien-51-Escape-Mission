extends Node
class_name CharacterAnimation

var sprite: AnimatedSprite2D
var weapon_holder: Node2D 
var cardinal_direction: Vector2 = Vector2.DOWN
var state: String = "idle"
var damage_timer: Timer
var is_flying: bool = false
var vessel : bool = false
var smooth_dir : Vector2 = Vector2.ZERO

func init(player_sprite: AnimatedSprite2D, timer: Timer, weaponholder: Node2D):
	sprite=player_sprite
	damage_timer=timer
	weapon_holder=weaponholder
	Signals.vessel_code.connect(vessel_code)

func update(character):
	if set_state(character) or set_direction(character):
		sprite.play(state + "_" + anim_direction())

func set_direction(character) -> bool:
	var vel = character.velocity
	if vel == Vector2.ZERO:
		return false
	var new_direction: Vector2
	if abs(vel.x) > abs(vel.y):
		new_direction = Vector2.LEFT if vel.x < 0 else Vector2.RIGHT
	else:
		new_direction = Vector2.UP if vel.y < 0 else Vector2.DOWN
	if new_direction == cardinal_direction:
		return false
	cardinal_direction = new_direction
	character.sprite.flip_h = (cardinal_direction == Vector2.LEFT)
	return true

func set_state(character) -> bool:
	var new_state: String
	if vessel:
		new_state = "vessel"
	elif is_flying:
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
		player_and_weapon_changing_color(Color(1, 0, 0, 1), Color(1, 0, 0, 1))
		damage_timer.start()
		
		while (!damage_timer.is_stopped()):
			await get_tree().create_timer(0.1).timeout
			player_and_weapon_changing_color(Color(0.431, 0.0, 0.0, 0.0),Color(0.431, 0.0, 0.0, 0.0))
			await get_tree().create_timer(0.1).timeout
			player_and_weapon_changing_color(Color(1,1,1),Color(1,1,1))
		
		damage_timer.stop()

func player_dying(player_revives: int):
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.play("dying")
	await sprite.animation_finished
	
	if player_revives > 0:
		player_revive()
	else:
		Signals.show_death_menu.emit()
		sprite.process_mode = Node.PROCESS_MODE_INHERIT

func player_revive():
	Signals.player_revive.emit()
	sprite.play("idle_down")
	pass

func player_changing_color(player_color: Color):
	sprite.modulate = player_color

func player_and_weapon_changing_color(player_color: Color, weapon_holder_color: Color):
	sprite.modulate = player_color
	weapon_holder.modulate = weapon_holder_color

func vessel_code():
	print("dweidi")
	vessel=true

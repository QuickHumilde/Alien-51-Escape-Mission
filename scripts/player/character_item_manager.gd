extends Node
class_name CharacterItems

@onready var player: Character

func init(charac: Character):
	player = charac

func apply_item(type: int, value: float):
	match type:
		1: player.stats.modify_speed(value)
		2: player.stats.increase_max_health(value)
		3: player.stats.heal(value)
		4: player.stats.increase_extra_health(value)
		5: player.stats.modify_size(value)

func modify_speed(value: float):
	apply_item(1, value)
	
func increase_max_health(value: float):
	apply_item(2, value)

func heal(value: float):
	apply_item(3, value)

func increase_extra_health(value: float):
	apply_item(4, value)
	
func modify_size(value: float):
	apply_item(5, value)

func give_weapon(weapon_id: int):
	player.combat.add_weapon(weapon_id)

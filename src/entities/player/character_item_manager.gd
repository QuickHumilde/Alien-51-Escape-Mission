extends Node
class_name CharacterItems

@onready var player: Character

func init(charac: Character):
	player = charac

func apply_item(type: int, value: int):
	match type:
		1: player.stats.modify_speed(value)
		2: player.stats.increase_max_health(value)
		3: player.stats.heal(value)
		4: player.stats.increase_extra_health(value)
		5: player.stats.modify_size(value)

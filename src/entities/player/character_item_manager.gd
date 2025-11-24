extends Node
class_name CharacterItems

@onready var player = get_parent().get_parent()

func apply_item(type: int, value: int, overheal: bool=false):
	match type:
		1: player.stats.modify_speed(value)
		2: player.stats.increase_max_health(value)
		3: player.stats.heal(value, overheal)
		4: player.stats.modify_size(value)

extends Node
class_name ItemModifier

func get_bonus(stat_name: String, _player):
	match stat_name:
		_:
			return 0.0

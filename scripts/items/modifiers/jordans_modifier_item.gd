extends ItemModifier
class_name JordansModifierItem

var bonus_speed: float = 15.0

func get_bonus(stat_name: String, _player) -> float:
	match stat_name:
		"speed":
			return bonus_speed
		_:
			return 0.0

extends ItemModifier
class_name Divisor3ModifierItem

var divisor_activation: int = 3
var bonus_speed: float = 10.0

func get_bonus(stat_name: String, player) -> float:

	if divisor_activation % int(player.health) != 0:
		return 0.0

	match stat_name:
		"speed":
			return bonus_speed
		_:
			return 0.0

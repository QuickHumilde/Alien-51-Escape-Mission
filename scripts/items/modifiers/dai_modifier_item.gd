extends ItemModifier
class_name DaiModifierItem

var percentage_activation := 0.35
var bonus_speed := 20.0
var bonus_damage := 2.0

func get_bonus(stat_name: String, player) -> float:
	var hp_percent : float = player.health / player.max_health

	if hp_percent > percentage_activation:
		return 0.0

	match stat_name:
		"speed":
			return bonus_speed
		"damage":
			return bonus_damage
		_:
			return 0.0

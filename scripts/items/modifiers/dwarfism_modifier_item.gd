extends ItemModifier
class_name DwarfismModifierItem

var invulnerability_time_decrease: float = -0.2
var size_decrease: float = -0.3
var max_health_decrease: float = -1

func get_bonus(stat_name: String, player: CharacterStats) -> float:
	match stat_name:
		"invulnerability_time":
			return invulnerability_time_decrease
		"max_health":
			return max_health_decrease
		"size":
			return size_decrease
		_:
			return 0.0
			

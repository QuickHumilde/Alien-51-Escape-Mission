extends ItemModifier
class_name SocksModifierItem

var percentage_activation: float = 0.35
var bonus_speed: float = 20.0
var bonus_damage: float= 2.0

func get_bonus(stat_name: String, player: CharacterStats) -> float:
	match stat_name:
		_:
			return 0.0
	
func avoid_tramp_damage():
	return true

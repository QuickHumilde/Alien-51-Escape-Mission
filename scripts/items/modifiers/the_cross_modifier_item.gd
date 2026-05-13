extends ItemModifier
class_name TheCrossModifierItem

var player: Character
var revives_aviable: float = 1
var invulnerability_time_increase: float = 0.1

func _init(body: Character) -> void:
	player= body

func get_bonus(stat_name: String, _player: CharacterStats) -> float:
	match stat_name:
		"invulnerability_time":
			return invulnerability_time_increase
		_:
			return 0.0
		
func revive_player() -> Array:
	var can_revive: bool = false
	if revives_aviable > 0:
		can_revive = true
		revives_aviable-=1
	return [can_revive]

func get_revives_quantity():
	return revives_aviable

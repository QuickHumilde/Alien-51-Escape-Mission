extends ItemModifier
class_name MassiveRageModifierItem

var player: Character
var damage_increase: float = 0

func _init(body: Character) -> void:
	player= body

func get_bonus(stat_name: String, _player: CharacterStats):
	if player.stats.extra_damage <= 0:
		damage_increase = 1.0
	else:
		damage_increase = player.stats.extra_damage
	
	match stat_name:
		"damage":
			return damage_increase
		_:
			return 0.0
		
func modify_incoming_damage(amount: float) -> float:
	return amount * 2.0

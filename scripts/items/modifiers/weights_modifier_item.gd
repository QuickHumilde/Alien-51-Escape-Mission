extends ItemModifier
class_name WeightsControllerModifierItem

var player: Character
var damage_increase: float = 1
var size_increase: float = 0.20

func _init(body: Character) -> void:
	player = body

func get_bonus(stat_name: String, _player: CharacterStats):
	match stat_name:
		"damage":
			return damage_increase
		"size":
			return size_increase
		_:
			return 0.0

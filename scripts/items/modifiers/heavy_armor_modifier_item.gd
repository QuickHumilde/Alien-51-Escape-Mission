extends ItemModifier
class_name HeavyArmorModifierItem

var extra_health_increase: int = 2
var speed_decrease: float = -10
var player: Character

func _init(body: Character) -> void:
	player= body
	Signals.floor_changed.connect(_on_floor_changed)

func get_bonus(stat_name: String, _player: CharacterStats):
	match stat_name:
		"speed":
			return speed_decrease
		_:
			return 0.0
		
func _on_floor_changed():
	player.items.increase_extra_health(extra_health_increase)

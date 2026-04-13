extends ItemModifier
class_name WhetstoneModifierItem

var player: Character
var increase_per_room: float = 0.15
var damage_increase: float = 0

func _init(body: Character) -> void:
	player = body
	Signals.room_cleared.connect(_on_room_cleaned)
	Signals.weapon_changed.connect(_on_weapon_changed)

func get_bonus(stat_name: String, _player: CharacterStats):
	match stat_name:
		"damage":
			return damage_increase
		_:
			return 0.0

func _on_weapon_changed():
	damage_increase = 0
	Signals.stats_changed.emit()

func _on_room_cleaned():
	damage_increase += increase_per_room
	Signals.stats_changed.emit()

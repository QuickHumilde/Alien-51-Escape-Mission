extends ItemModifier
class_name TheCrossModifierItem

var player: Character
var revives_aviable: float = 1

func _init(body: Character) -> void:
	player= body

func revive_player() -> Array:
	var can_revive: bool = false
	if revives_aviable > 0:
		can_revive = true
		revives_aviable-=1
	return [can_revive]

func get_revives_quantity():
	return revives_aviable

extends ItemModifier
class_name RevivemintModifierItem

var player: Character
var revives_aviable: float = 1

func _init(body: Character) -> void:
	player= body

func revive_player() -> Array:
	var can_revive: bool = false
	var new_health: float = -1
	if revives_aviable > 0:
		can_revive = true
		revives_aviable-=1
		new_health = player.stats.get_max_health() 
	return [can_revive, new_health]

func get_revives_quantity():
	return revives_aviable

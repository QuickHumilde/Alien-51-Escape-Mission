extends Item
class_name RevivemintItem

var resurrections: int = 1
@export var ext_id: int = 20

func _ready():
	id = 20
	name_key = "item_revivemint_name"
	desc_key = "item_revivemint_desc"
	item_texture = "res://assets/sprites/items/Revivemint.png"
	super._ready()
	
func give_changes(body: Character):
	body.items.heal(body.stats.get_max_health())
	body.stats.modify_revives(resurrections)
	destroy_on_pickup()

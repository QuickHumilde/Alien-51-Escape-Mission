extends Item
class_name RevivemintItem

@export var ext_id: int = 20

func _ready():
	id = 20
	name_key = "item_revivemint_name"
	desc_key = "item_revivemint_desc"
	item_texture = "res://assets/sprites/items/Revivemint.png"
	super._ready()
	
func give_changes(body: Character):
	var revivemint_modifier = RevivemintModifierItem.new(body)
	body.items.give_modifiers(revivemint_modifier)
	body.stats._emit_health_changed_signal()
	destroy_on_pickup()

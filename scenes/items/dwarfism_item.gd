extends Item
class_name DwarfismItem

@export var ext_id: int = 21

func _ready():
	id = 21
	name_key = "item_dwarfism_name"
	desc_key = "item_dwarfism_desc"
	item_texture = "res://assets/sprites/provisional/Dwarfism.png"
	super._ready()
	
func give_changes(body: Character):
	var dai_modifier = DwarfismModifierItem.new()
	body.items.give_modifiers(dai_modifier)
	destroy_on_pickup()

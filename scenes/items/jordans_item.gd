extends Item
class_name JordansItem

@export var ext_id: int = 18

func _ready():
	id = 18
	name_key = "item_jordans_name"
	desc_key = "item_jordans_desc"
	item_texture = "res://assets/sprites/provisional/Jordans.png"
	super._ready()

func give_changes(body: Character):
	var jordans_modifier = JordansModifierItem.new()
	body.items.give_modifiers(jordans_modifier)
	destroy_on_pickup()

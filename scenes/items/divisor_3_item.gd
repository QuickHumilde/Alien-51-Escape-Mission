extends Item
class_name Divisor3Item

@export var ext_id: int = 8

func _ready():
	id = 8
	name_key = "item_divisor_3_name"
	desc_key = "item_divisor_3_desc"
	item_texture = "res://assets/sprites/items/Divisor3_Item.png"
	super._ready()

func give_changes(body: Character):
	var divisor3_modifier = Divisor3ModifierItem.new()
	body.items.give_modifiers(divisor3_modifier)
	destroy_on_pickup()

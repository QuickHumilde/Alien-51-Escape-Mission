extends Item
class_name TheCrossItem

@export var ext_id: int = 9

func _ready():
	id = 9
	name_key = "item_the_cross_name"
	desc_key = "item_the_cross_desc"
	item_texture = "res://assets/sprites/items/TheCross_Item.png"
	
	super._ready()

func give_changes(body: Character):
	var the_cross_modifier = TheCrossModifierItem.new(body)
	body.items.give_modifiers(the_cross_modifier)
	body.stats._emit_health_changed_signal()
	destroy_on_pickup()

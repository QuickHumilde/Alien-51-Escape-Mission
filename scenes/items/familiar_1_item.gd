extends Item
class_name FamiliarItem

@export var ext_id: int = 29 

func _ready() -> void:
	id = ext_id
	name_key = "item_familiar_name"
	desc_key = "item_familiar_desc"
	item_texture = "res://assets/sprites/items/Familiar1Item.png"
	super._ready()

func give_changes(body: Character) -> void:
	var modifier = FamiliarModifierItem.new(body)
	body.items.give_modifiers(modifier)
	destroy_on_pickup()

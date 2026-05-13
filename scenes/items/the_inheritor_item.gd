extends Item
class_name TheInheritorItem

@export var ext_id: int = 29 

func _ready() -> void:
	id = ext_id
	name_key = "item_the_inheritor_name"
	desc_key = "item_the_inheritor_desc"
	item_texture = "res://assets/sprites/items/Familiar1Item.png"
	super._ready()

func give_changes(body: Character) -> void:
	var modifier = TheInheritorModifierItem.new(body)
	body.items.give_modifiers(modifier)
	destroy_on_pickup()

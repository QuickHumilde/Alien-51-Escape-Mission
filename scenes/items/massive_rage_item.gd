extends Item
class_name MassiveRageItem

@export var ext_id: int = 23

func _ready():
	id = 23
	name_key = "item_massive_rage_name"
	desc_key = "item_massive_rage_desc"
	item_texture = "res://assets/sprites/items/MassiveRage.png"
	super._ready()

func give_changes(body: Character):
	var massive_rage_modifier = MassiveRageModifierItem.new(body)
	body.items.give_modifiers(massive_rage_modifier)
	destroy_on_pickup()

extends Item
class_name SocksItem

@export var ext_id: int = 31

func _ready() -> void:
	id = ext_id
	name_key = "item_socks_name"
	desc_key = "item_socks_desc"
	item_texture = "res://assets/sprites/items/SocksItem.png"
	super._ready()

func give_changes(body: Character) -> void:
	var modifier = SocksModifierItem.new()
	body.items.give_modifiers(modifier)
	destroy_on_pickup()

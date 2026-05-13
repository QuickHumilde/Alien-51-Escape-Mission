extends Item

@export var ext_id: int = 32

func _ready():
	id = ext_id
	price = 10
	name_key = "item_deodorant_name"
	desc_key = "item_deodorant_desc"
	item_texture = "res://assets/sprites/items/DeodorantItem.png"
	super._ready()
	
func give_changes(body: Character):
	var modifier = DeodorantModifierItem.new(body)
	body.items.give_modifiers(modifier)
	destroy_on_pickup()

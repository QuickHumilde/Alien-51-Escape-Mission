extends Item

@export var ext_id: int = 23

func _ready():
	id = 23
	name_key = "item_whetstone_name"
	desc_key = "item_whetstone_desc"
	item_texture = "res://assets/sprites/items/Whetstone.png"
	super._ready()
	
func give_changes(body: Character):
	var whetstone_modifier = WhetstoneModifierItem.new(body)
	body.items.give_modifiers(whetstone_modifier)
	destroy_on_pickup()

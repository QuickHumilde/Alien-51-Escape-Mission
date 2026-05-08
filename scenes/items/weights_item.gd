extends Item

@export var ext_id: int = 26

func _ready():
	id = 26
	price = 10
	name_key = "item_weights_name"
	desc_key = "item_weights_desc"
	item_texture = "res://assets/sprites/items/WeightsItem.png"
	super._ready()
	
func give_changes(body: Character):
	var weights_controller_modifier = WeightsControllerModifierItem.new(body)
	body.items.give_modifiers(weights_controller_modifier)
	destroy_on_pickup()

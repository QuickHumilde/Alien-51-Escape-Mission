extends Item
class_name UFOItem

var fly: bool =true

func _ready():
	id = 3
	name_key = "item_ufo_name"
	desc_key = "item_ufo_desc"
	item_texture = "res://assets/sprites/items/UFO_Item.png"
	_initiate_detectors()

func give_changes(body:Character):
	body.items.give_fly(fly)
	destroy_on_pickup()

extends Item
class_name UFOItem

var fly: bool =true
@export var id: int = 3

func _ready():
	name_key = "item_ufo_name"
	desc_key = "item_ufo_desc"
	item_texture = "res://assets/sprites/items/UFO_Item.png"
	super._ready()

func give_changes(body:Character):
	body.items.give_fly(fly)
	destroy_on_pickup()

extends Item
class_name TheCrossItem

var revive : float = 1.0
@export var ext_id: int = 9

func _ready():
	id = 9
	name_key = "item_the_cross_name"
	desc_key = "item_the_cross_desc"
	item_texture = "res://assets/sprites/items/TheCross_Item.png"
	
	super._ready()

func give_changes(body: Character):
	body.items.modify_revives(revive)
	destroy_on_pickup()

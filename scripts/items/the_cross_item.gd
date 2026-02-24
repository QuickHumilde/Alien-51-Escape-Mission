extends Item
class_name TheCrossItem

var revive : float = 1.0
var id = 9

func _ready():
	name_key = "item_dai_name"
	desc_key = "item_dai_name"
	item_texture = "res://assets/sprites/extras/ItemPedestal.png"
	
	super._ready()

func give_changes(body: Character):
	body.items.modify_revives(revive)
	destroy_on_pickup()

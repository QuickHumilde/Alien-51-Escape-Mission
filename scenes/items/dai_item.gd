extends Item
class_name DaiItem

var health : float = 1
@export var ext_id: int = 7

func _ready():
	id = 7
	name_key = "item_dai_name"
	desc_key = "item_dai_desc"
	item_texture = "res://assets/sprites/items/DAI_Item.png"
	super._ready()

func give_changes(body: Character):
	var dai_modifier = DaiModifierItem.new()
	body.items.give_modifiers(dai_modifier)
	destroy_on_pickup()

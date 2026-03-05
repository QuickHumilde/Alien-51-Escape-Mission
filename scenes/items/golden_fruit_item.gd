extends Item
class_name GoldenFruitItem

var health_increase : float = 2
@export var id: int = 1

func _ready():
	name_key = "item_golden_fruit_name"
	desc_key = "item_golden_fruit_desc"
	item_texture = "res://assets/sprites/items/GoldenFruit_Item.png"
	super._ready()
	
func give_changes(body: Character):
	body.items.increase_extra_health(health_increase)
	destroy_on_pickup()

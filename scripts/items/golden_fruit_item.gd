extends Item
class_name GoldenFruitItem

var health_increase : float = 2

func _ready():
	id = 1
	name_key = "item_golden_fruit_name"
	desc_key = "item_golden_fruit_desc"
	item_texture = "res://assets/sprites/items/GoldenFruit_Item.png"
	_initiate_detectors()

# 1. Speed, 2. MaxHealth, 3. Health, 4. ExtraHealth, 5. Size
func give_changes(body: Character):
	body.items.increase_extra_health(health_increase)
	queue_free()

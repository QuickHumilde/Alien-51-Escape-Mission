extends Item
class_name GoldenFruitItem

var health_increase : float = 2

func _ready():
	id = 1
	name_key = "item_golden_fruit_name"
	desc_key = "item_golden_fruit_desc"
	_initiate_detectors()

# 1. Speed, 2. MaxHealth, 3. Health, 4. ExtraHealth, 5. Size
func give_changes(body):
	body.items.apply_item(4, 2)
	queue_free()

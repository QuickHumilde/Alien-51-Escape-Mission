extends Item
class_name GoldenFruitItem

var health_increase := 2

func _ready():
	id = 1
	name_key = "item_golden_fruit_name"
	desc_key = "item_golden_fruit_desc"
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)

func _on_hitbox_enter(body):
	if body.is_in_group("player"):
		body.items.apply_item(4, 2)
		queue_free()

func _on_hitbox_enter_description(body):
	if body.is_in_group("player"):
		show_description()

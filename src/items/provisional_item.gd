extends Item
class_name ProvisionalItem

var speed_increase = 500
var max_health_increase = 2
var scale_increase = 0.5

var item_name = "You but bigger"
var description = "Item that increases speed and life"

func _ready():
	id = 0
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)

# 1. Speed, 2. MaxHealt, 3. Health (+parameter bool), 4. Scale
func _on_hitbox_enter(body):
	if body.is_in_group("player"):
		body.items.apply_item(1, speed_increase)
		body.items.apply_item(2, max_health_increase)
		body.items.apply_item(4, scale_increase)
		queue_free()

func _on_hitbox_enter_description(body):
	if body.is_in_group("player"):
		print("Nombre: " + item_name)
		print("Descripción: " + description)

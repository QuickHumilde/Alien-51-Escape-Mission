extends Item
class_name GoldenAppleItem

var health_increase = 2
var overheal = true

func _ready():
	id = 1
	item_name= "Golden Fruit"
	description = "Item that gives you 2 life but does not increase your maximum life"
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)
	pass
	
# 1. Speed, 2. MaxHealt, 3. Health (+parameter bool), 4. Scale
func _on_hitbox_enter(body):
	if body.is_in_group("player"):
		body.items.apply_item(3, health_increase, overheal)
		queue_free()

func _on_hitbox_enter_description(body):
	if body.is_in_group("player"):
		print("Nombre: " + item_name)
		print("Descripción: " + description)

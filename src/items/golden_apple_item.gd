extends Item
class_name GoldenAppleItem

var health_increase = 2

func _ready():
	id = 1
	item_name= "Golden Fruit"
	description = "Item that gives you 2 life but does not increase your maximum life"
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)
	pass
	
# 1. Speed, 2. MaxHealt, 3. Health
func _on_hitbox_enter(body):
	if body.is_in_group("player"):
		body.get_item_increase(3, health_increase)
		queue_free()

func _on_hitbox_enter_description(body):
	if body.is_in_group("player"):
		print("Nombre: "+ item_name)
		print("Description "+ description )

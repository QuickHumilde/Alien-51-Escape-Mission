extends Item
class_name ProvisionalItem

var speed_increase = 500
var max_health_increase = 2
var scale_decrease = 2

func _ready():
	id = 0
	item_name= "You but bigger"
	description = "Item that increases speed and life"
	
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)
	pass
	
# 1. Speed, 2. MaxHealt, 3. Health
func _on_hitbox_enter(body):
	if body.is_in_group("player"):
		body.get_item_increase(1, speed_increase)
		body.get_item_increase(3, max_health_increase)

		queue_free()

func _on_hitbox_enter_description(body):
	if body.is_in_group("player"):
		print("Nombre: "+ item_name)
		print("Description "+ description )

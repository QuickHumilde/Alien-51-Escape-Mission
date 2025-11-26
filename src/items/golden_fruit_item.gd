extends Item
class_name GoldenFruitItem

var health_increase := 2
var overheal := true

@export var name_key := "item_golden_fruit_name"
@export var desc_key := "item_golden_fruit_desc"

func _ready():
	id = 1
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)

func get_item_name() -> String:
	return tr(name_key)

func get_description() -> String:
	return tr(desc_key)

func _on_hitbox_enter(body):
	if body.is_in_group("player"):
		body.items.apply_item(3, health_increase, overheal)
		queue_free()

func _on_hitbox_enter_description(body):
	if body.is_in_group("player"):
		print("Nombre: " + get_item_name())
		print("Descripción: " + get_description())

extends Item
class_name ProvisionalItem

var speed_increase = 500
var max_health_increase = 2
var scale_increase = 1.5

func _ready():
	#TranslationServer.set_locale("es")
	id = 0
	name_key="item_provisional_item_name"
	desc_key="item_provisional_item_desc"
	_initiate_detectors()

# 1. Speed, 2. MaxHealth, 3. Health, 4. ExtraHealth, 5. Size
func _on_hitbox_enter(body):
	if body.is_in_group("player"):
		body.items.apply_item(1, speed_increase)
		body.items.apply_item(2, max_health_increase)
		body.items.apply_item(5, scale_increase)
		queue_free()

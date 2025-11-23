extends CanvasLayer

func update_health(new_health: int):
	$HealthLabel.text = "Vida: %d" % new_health

func update_item(item_name: String):
	$ItemLabel.text = "Objeto: %s" % item_name

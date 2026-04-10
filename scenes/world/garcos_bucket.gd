extends StaticBody2D

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D

func _ready() -> void:
	Signals.purchased_shop_item.connect(_on_purchased_shop_item)
	
func _on_purchased_shop_item():
	sprite.frame = 1

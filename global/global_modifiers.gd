extends Node

var shop_price_mult: float = 1.0
var extra_coins_on_clear: int = 0

func _ready() -> void:
	Signals.show_death_menu.connect(_on_death_menu)

func reset() -> void:
	shop_price_mult = 1.0
	extra_coins_on_clear = 0

func apply_shop_price(base_price: int) -> int:
	return int(round(base_price * shop_price_mult))

func _on_death_menu():
	reset()

func modify_shop_shop_price_mult(big_shot: float):
	if shop_price_mult+big_shot >= 0.0 :
		shop_price_mult+=big_shot
		Signals.shop_price_mult_changed.emit()

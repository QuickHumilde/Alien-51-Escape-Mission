extends Node
class_name PlayerInventory

@export var money: int = 3
@export var items: int = 0
var modifiers: Array = []
var player: Character = null

func init(p: Character):
	player = p

func _ready() -> void:
	Signals.item_picked.connect(_on_item_picked)

func add_money(amount: int):
	if amount > 0:
		money += amount
		Signals.money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		Signals.money_changed.emit(money)
		return true
	return false

func get_money() -> int:
	return money

func get_items() -> int:
	return items

func get_modifiers():
	return modifiers

func give_modifiers(modifier):
	modifiers.append(modifier)
	if player:
		player.stats._invalidate_stats()

func _on_item_picked(_id: int = -1):
	items += 1
	Signals.items_changed.emit()

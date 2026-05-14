extends Node
class_name PlayerInventory

@export var money: int = 3
@export var items: int = 0
@export var modifiers: Array = []
var player: Character = null

var picked_item_ids: Array[int] = []

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

func _on_item_picked(id: int = -1):
	items += 1
	if id >= 0:
		picked_item_ids.append(id)
	Signals.items_changed.emit()

func can_revive() -> Array:
	for mod in get_modifiers():
		if mod.has_method("get_revives_quantity") and mod.get_revives_quantity() > 0:
			return mod.revive_player()
	return []

func get_revives():
	var quantity: float = 0
	for mod in get_modifiers():
		if mod.has_method("get_revives_quantity"):
			quantity += mod.get_revives_quantity()
	return quantity

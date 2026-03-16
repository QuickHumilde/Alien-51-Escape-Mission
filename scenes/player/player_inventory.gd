extends Node
class_name PlayerInventory

@export var money: int = 5

func add_money(amount: int):
	if amount > 0:
		money += amount
		Signals.money_changed.emit(money)
	
func spend_money(amount: int) -> bool:
	var spent : bool = false
	if money >= amount:
		money -= amount
		Signals.money_changed.emit(money)
		spent = true
	return spent

func get_money() -> int:
	return money

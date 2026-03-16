extends Pickup

@export var money: int = 1

func _on_pick_up(player : Character):
	player.inventory.add_money(money) 
	destroy()

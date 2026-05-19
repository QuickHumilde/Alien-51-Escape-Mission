extends Pickup

@export var money: int = 1

func _on_pick_up(player : Character):
	if picked == false:
		picked=true
		player.inventory.add_money(money) 
		AudioManager.play_sfx("coin_collected", -2.0)
		destroy()

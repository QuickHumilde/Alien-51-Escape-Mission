extends Pickup

@export var extra_health: int = 1
@export var player_collision_layer: int = 3

func _on_pick_up(player: Character):
	if picked == false:
		player.stats.increase_extra_health(extra_health)
		picked=true
		destroy()

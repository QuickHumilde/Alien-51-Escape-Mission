extends Node
class_name DashAbility

var cooldown := 2.0
var last_use := -999.0
var dash_speed := 400.0
var dash_time := 0.2

func activate_with_player(player: Character):
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_use < cooldown:
		return

	last_use = now
	start_dash(player)

func start_dash(player: Character):
	var normal_speed = player.stats.speed
	player.stats.speed += dash_speed
	await player.get_tree().create_timer(dash_time).timeout

	player.stats.speed = normal_speed

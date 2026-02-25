extends Node
class_name DashAbility

signal cooldown_started(duration)
signal cooldown_progress(progress)
signal cooldown_finished()

var cooldown := 3.5
var last_use := -999.0
var dash_speed := 400.0
var dash_time := 0.2

func activate_with_player(player: Character):
	if player.velocity != Vector2(0.0, 0.0):
		var now = Time.get_ticks_msec() / 1000.0
		if now - last_use < cooldown:
			return

		last_use = now

		emit_signal("cooldown_started", cooldown)

		start_dash(player)
		start_cooldown_timer(player)

func start_cooldown_timer(player: Character):
	var elapsed := 0.0

	while elapsed < cooldown:
		await player.get_tree().physics_frame
		elapsed += player.get_process_delta_time()
		emit_signal("cooldown_progress", elapsed / cooldown)
	emit_signal("cooldown_finished")

func start_dash(player: Character):
	var normal_speed = player.stats.speed
	player.stats.speed += dash_speed

	await player.get_tree().create_timer(dash_time).timeout

	player.stats.speed = normal_speed
	
	await player.get_tree().create_timer(dash_time+0.2).timeout

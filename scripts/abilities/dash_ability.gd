extends Node
class_name DashAbility

signal cooldown_started(duration)
signal cooldown_progress(progress)
signal cooldown_finished()

var cooldown := 3.5
var dash_speed := 400.0
var dash_time := 0.2
var is_on_cooldown := false

func activate_with_player(player: Character):
	if player.velocity != Vector2(0.0, 0.0):
		if is_on_cooldown:
			return
		is_on_cooldown = true
		emit_signal("cooldown_started")
		start_dash(player)
		start_cooldown_timer(player)

func start_cooldown_timer(player: Character):
	var timer := Timer.new()
	timer.wait_time = cooldown
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.add_child(timer)
	timer.start()
	while timer.time_left > 0:
		await player.get_tree().process_frame
		var progress := 1.0 - (timer.time_left / cooldown)
		emit_signal("cooldown_progress", progress)
	is_on_cooldown = false
	emit_signal("cooldown_finished")
	timer.queue_free()

func start_dash(player: Character):
	var normal_speed = player.stats.speed
	player.stats.speed += dash_speed
	player.change_player_damagable_timer(false, dash_time+0.2)
	player.animation.player_and_weapon_changing_color(Color(0.842, 2.433, 2.285, 0.549), Color(0.842, 2.433, 2.285, 0.549))
	await player.get_tree().create_timer(dash_time).timeout
	player.animation.player_and_weapon_changing_color(Color(1,1,1), Color(1,1,1))
	player.stats.speed = normal_speed

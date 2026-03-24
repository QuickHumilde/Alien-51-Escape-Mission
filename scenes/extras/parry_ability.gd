extends Node2D
class_name ParryAbility

@onready var area: Area2D = $Area2D

signal cooldown_started(duration)
signal cooldown_progress(progress)
signal cooldown_finished()

var cooldown: float = 4.5
var is_on_cooldown:bool = false

func activate_with_player(player: Character):
	if !player.is_player_damagable():
		return
	if is_on_cooldown:
		return
	is_on_cooldown = true
	emit_signal("cooldown_started")
	start_parry(player)
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

func start_parry(player: Character):
	var overlapping_bodies= area.get_overlapping_areas()
	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			var knockback_direction = (body.global_position - player.global_position).normalized()
			body.apply_knockback(knockback_direction, 350.0)
		if body.is_in_group("bullet"):
			var new_direction = (player.global_position - body.global_position).normalized()
			body.change_direction(new_direction, "player")

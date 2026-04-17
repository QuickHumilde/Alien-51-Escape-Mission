extends Node
class_name DashAbility

signal cooldown_started(duration)
signal cooldown_progress(progress)
signal cooldown_finished()

var cooldown: float = 3.5
var dash_speed: float = 300.0
var dash_time: float = 0.2
var is_on_cooldown: bool = false
var _player: Character = null

var jordans_item_id = 18

func activate_with_player(player: Character):
	if player.velocity != Vector2.ZERO:
		if is_on_cooldown:
			return
		is_on_cooldown = true
		emit_signal("cooldown_started")
		start_dash(player)
		play_sound()
		start_cooldown_timer(player)

func start_cooldown_timer(player: Node) -> void:
	is_on_cooldown = true

	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		is_on_cooldown = false
		return

	var end_timer: Timer = Timer.new()
	end_timer.one_shot = true
	end_timer.wait_time = cooldown
	end_timer.process_mode = Node.PROCESS_MODE_PAUSABLE

	var tick: Timer = Timer.new()
	tick.one_shot = false
	tick.wait_time = 0.05
	tick.process_mode = Node.PROCESS_MODE_PAUSABLE

	player.add_child(end_timer)
	player.add_child(tick)

	var started_at := Time.get_ticks_msec()
	var cooldown_ms := int(cooldown * 1000.0)

	tick.timeout.connect(func ():
		if not is_instance_valid(end_timer):
			return
		var elapsed_ms := Time.get_ticks_msec() - started_at
		var progress = clamp(float(elapsed_ms) / float(cooldown_ms), 0.0, 1.0)
		emit_signal("cooldown_progress", progress)
	)

	end_timer.timeout.connect(func ():
		if is_instance_valid(tick):
			tick.stop()
			tick.queue_free()
		is_on_cooldown = false
		emit_signal("cooldown_progress", 1.0)
		emit_signal("cooldown_finished")
		end_timer.queue_free()
	)

	player.tree_exited.connect(func ():
		if is_instance_valid(end_timer):
			end_timer.stop()
			end_timer.queue_free()
		if is_instance_valid(tick):
			tick.stop()
			tick.queue_free()
		is_on_cooldown = false
	, CONNECT_ONE_SHOT)

	emit_signal("cooldown_progress", 0.0)
	tick.start()
	end_timer.start()

func start_dash(player: Character):
	var base_speed := player.stats.get_speed()
	var dash_final_speed := base_speed + dash_speed
	player.movement.override_speed(dash_final_speed)
	player.change_player_damagable_timer(false, dash_time + 0.2)
	player.animation.player_and_weapon_changing_color(Color(0.842, 2.433, 2.285, 0.549),Color(0.842, 2.433, 2.285, 0.549))
	await player.get_tree().create_timer(dash_time).timeout
	player.animation.player_and_weapon_changing_color(Color(1,1,1), Color(1,1,1))
	player.movement.clear_override_speed()

func get_player(body: Character):
	_player = body

func check_items(player: Character):
	for modifier in player.inventory.get_modifiers():
		if modifier is JordansModifierItem:
			_on_item_picked(jordans_item_id)

func _on_item_picked(id: int = -1):
	if id == jordans_item_id:
		cooldown -= 0.5
		dash_speed += 100
		dash_time += 0.075

func change_ability(new_ability_position):
	var item_scene: PackedScene = load("res://scenes/items/dash_ability_item.tscn")
	var inst = item_scene.instantiate()
	_player.get_tree().current_scene.add_child(inst)
	inst.global_position = new_ability_position
	inst.disable_pickup(2.0)
	queue_free()

func play_sound():
	var pitch: float = randf_range(0.9, 1.2)
	AudioManager.play_sfx("dash_1", -23.0, pitch)

extends Node
class_name ParryAbility

@onready var area: Area2D = $Area2D

@export var damage: float = 2.0

signal cooldown_started(duration: float)
signal cooldown_progress(progress: float)
signal cooldown_finished()

var cooldown: float = 4.0
var is_on_cooldown: bool = false
var failed: bool = true
var _cooldown_end_ms: int = 0

var player: Character = null

func get_icon_path() -> String:
	return "res://assets/sprites/items/ParryAbility.png"

func activate_with_player(_player: Character):
	# robustez: si no está seteado, usa el parámetro
	if player == null or not is_instance_valid(player):
		player = _player

	if player == null or not is_instance_valid(player):
		return

	if not player.is_player_damagable():
		return

	if is_on_cooldown:
		return

	is_on_cooldown = true
	failed = true

	emit_signal("cooldown_started", cooldown)
	emit_signal("cooldown_progress", 0.0)

	start_parry(player)

	play_sfx()

	start_cooldown_timer(player)

func start_cooldown_timer(_player: Node) -> void:
	_cooldown_end_ms = Time.get_ticks_msec() + int(cooldown * 1000.0)
	is_on_cooldown = true

	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		is_on_cooldown = false
		return

	var end_timer := Timer.new()
	end_timer.one_shot = true
	end_timer.wait_time = cooldown
	end_timer.process_mode = Node.PROCESS_MODE_PAUSABLE

	var tick := Timer.new()
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

	tick.start()
	end_timer.start()

func start_parry(_player: Character):
	if area == null or not is_instance_valid(area):
		return

	var overlapping_bodies = area.get_overlapping_areas()
	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			failed = false
			if body.has_method("apply_knockback"):
				var knockback_direction = (body.global_position - player.global_position).normalized()
				body.apply_knockback(knockback_direction, 350.0)
			if body.has_method("take_damage"):
				body.take_damage(damage)

		if body.is_in_group("bullet"):
			failed = false
			var new_direction = (player.global_position - body.global_position).normalized()
			body.change_direction(new_direction, "player")

func get_save_state() -> Dictionary:
	return {
		"is_on_cooldown": is_on_cooldown,
		"cooldown_remaining": get_cooldown_remaining()
	}

func load_save_state(state: Dictionary) -> void:
	var rem := float(state.get("cooldown_remaining", 0.0))
	if rem > 0.0:
		is_on_cooldown = true
		emit_signal("cooldown_started", rem)
		emit_signal("cooldown_progress", 0.0)
		_start_cooldown_with_remaining(player, rem)
	else:
		is_on_cooldown = false
		emit_signal("cooldown_progress", 1.0)
		emit_signal("cooldown_finished")

func get_cooldown_remaining() -> float:
	if not is_on_cooldown:
		return 0.0
	return max(0.0, float(_cooldown_end_ms - Time.get_ticks_msec()) / 1000.0)

func _start_cooldown_with_remaining(_player: Node, remaining: float) -> void:
	var old := cooldown
	cooldown = remaining
	start_cooldown_timer(player)
	cooldown = old

func get_player(body: Character):
	player = body

func change_ability(new_ability_position):
	var item_scene: PackedScene = load("res://scenes/items/parry_ability_item.tscn")
	var inst = item_scene.instantiate()
	get_tree().current_scene.add_child(inst)
	inst.global_position = new_ability_position
	inst.disable_pickup(2.0)
	queue_free()

func play_sfx():
	var pitch: float = randf_range(0.9, 1.1)
	if failed:
		AudioManager.play_sfx("failed_parry_1", -10, pitch)
	else:
		AudioManager.play_sfx("parry_1", -10, pitch)

func get_ability_scene_path() -> String:
	return "res://scenes/extras/parry_ability_scene.tscn"

extends Node
class_name SummerChairAbility

signal cooldown_started(duration)
signal cooldown_progress(progress)
signal cooldown_finished()

@export var cooldown: float = 6.0

var is_on_cooldown: bool = false
var _player: Character = null

func get_player(body: Character) -> void:
	_player = body

func activate_with_player(player: Character) -> void:
	if is_on_cooldown:
		return

	is_on_cooldown = true
	emit_signal("cooldown_started")

	
	_play_sound()

	start_cooldown_timer(player)
	
func start_cooldown_timer(player: Node) -> void:
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

func change_ability(new_ability_position):
	var item_scene: PackedScene = load("res://scenes/items/summer_chair_ability_item.tscn")
	var inst = item_scene.instantiate()
	_player.get_tree().current_scene.add_child(inst)
	inst.global_position = new_ability_position
	inst.disable_pickup(2.0)
	_player.animation.player_and_weapon_changing_color(Color(1,1,1), Color(1,1,1))
	_player.movement.clear_override_speed()
	queue_free()

func _play_sound() -> void:
	var pitch: float = randf_range(0.95, 1.1)
	AudioManager.play_sfx("wii_startup", -18.0, pitch)

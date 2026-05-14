extends Node
class_name SummerChairAbility

signal cooldown_started(duration: float)
signal cooldown_progress(progress: float)
signal cooldown_finished()

@export var max_uses: int = 3
var uses_left: int = 3

var player: Character = null

func get_player(body: Character) -> void:
	player = body
	if uses_left <= 0:
		uses_left = max_uses
	uses_left = clamp(uses_left, 0, max_uses)
	emit_signal("cooldown_started", 0.0)
	_emit_uses_progress()

func activate_with_player(_player: Character) -> void:
	if player == null or not is_instance_valid(player):
		player = _player
	if player == null or not is_instance_valid(player):
		return

	if uses_left <= 0:
		return

	var health: float = player_health_calcs()
	player.stats.heal(health)

	uses_left -= 1
	_play_sound()
	_emit_uses_progress()

	if uses_left <= 0:
		emit_signal("cooldown_finished")
		player.abilities.remove_current_ability()
		queue_free()

func _emit_uses_progress() -> void:
	var denom = max(1, max_uses)
	var progress := float(uses_left) / float(denom)
	emit_signal("cooldown_progress", progress)

func refill_uses() -> void:
	uses_left = max_uses
	emit_signal("cooldown_started", 0.0)
	_emit_uses_progress()

func change_ability(new_ability_position):
	var item_scene: PackedScene = load("res://scenes/items/summer_chair_ability_item.tscn")
	var inst = item_scene.instantiate()
	player.get_tree().current_scene.add_child(inst)
	inst.global_position = new_ability_position
	inst.disable_pickup(2.0)
	queue_free()

func player_health_calcs():
	var max_health: float = player.stats.get_max_health()
	return max_health * 2.0 / 3.0

func _play_sound() -> void:
	var pitch: float = randf_range(0.95, 1.1)
	AudioManager.play_sfx("oars_on_water", -5.0, pitch)

func get_save_state() -> Dictionary:
	return {
		"uses_left": uses_left,
		"max_uses": max_uses
	}

func load_save_state(state: Dictionary) -> void:
	max_uses = int(state.get("max_uses", max_uses))
	uses_left = int(state.get("uses_left", uses_left))
	uses_left = clamp(uses_left, 0, max_uses)

	emit_signal("cooldown_started", 0.0)
	_emit_uses_progress()

	if uses_left <= 0:
		emit_signal("cooldown_finished")

func get_icon_path() -> String:
	return "res://assets/sprites/items/SummerChairItem.png"

func sync_hud() -> void:
	emit_signal("cooldown_started", 0.0)
	_emit_uses_progress()
	if uses_left <= 0:
		emit_signal("cooldown_finished")

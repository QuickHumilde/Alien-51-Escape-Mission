extends Node2D
class_name ItemSpawner

@export var use_global_random: bool = true
@export var timer: float = 1.25

var spawned_item_id: int = -1
var has_spawned: bool = false
var was_picked: bool = false

func _ready() -> void:
	call_deferred("_spawn_item_deferred")

func get_spawner_key() -> String:
	return str(get_path())

func get_save_state() -> Dictionary:
	return {
		"has_spawned": has_spawned,
		"spawned_item_id": spawned_item_id,
		"was_picked": was_picked,
	}

func load_save_state(state: Dictionary) -> void:
	has_spawned = bool(state.get("has_spawned", false))
	spawned_item_id = int(state.get("spawned_item_id", -1))
	was_picked = bool(state.get("was_picked", false))

	if has_spawned and not was_picked and spawned_item_id >= 0:
		_spawn_specific_item(spawned_item_id)

func mark_picked() -> void:
	was_picked = true
	for c in get_children():
		c.queue_free()

func _spawn_item_deferred() -> void:
	if has_spawned or was_picked:
		return

	if get_child_count() > 0:
		has_spawned = true
		return

	if ItemManager.item_pool.is_empty():
		return

	var rng := GameManager.rng

	var item_id: int = ItemManager.pick_random_item_id(rng)
	if item_id < 0:
		return

	spawned_item_id = item_id
	has_spawned = true

	_spawn_specific_item(item_id)

	ItemManager.mark_removed(item_id)

func _spawn_specific_item(item_id: int) -> void:
	if get_child_count() > 0:
		return

	var ps: PackedScene = ItemManager.get_scene(item_id)
	if ps == null:
		return

	var inst := ps.instantiate()
	add_child(inst)

	if inst.has_method("disable_hitbox"):
		inst.disable_hitbox()

	inst.global_position = global_position

	if not Signals.item_picked.is_connected(_on_item_picked_global):
		Signals.item_picked.connect(_on_item_picked_global)

	await get_tree().create_timer(timer).timeout
	if inst != null and is_instance_valid(inst) and inst.has_method("enable_hitbox"):
		inst.enable_hitbox()

func _on_item_picked_global(id: int = -1) -> void:
	if not has_spawned:
		return
	if spawned_item_id != id:
		return

	await get_tree().process_frame
	if get_child_count() == 0:
		was_picked = true

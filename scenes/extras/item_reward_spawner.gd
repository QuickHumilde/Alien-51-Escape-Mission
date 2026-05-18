extends Node2D
class_name RoomClearItemSpawner

@export var activable: bool = true
@export var timer: float = 1.25
@export var use_global_random: bool = true

var has_spawned: bool = false
var spawned_item_id: int = -1
var was_picked: bool = false

func _ready() -> void:
	if not is_activable():
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	Signals.room_cleared.connect(_on_room_cleared)

# --- SAVE API ---
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

	# limpia hijos si ya estaba picked
	if was_picked:
		for c in get_children():
			c.queue_free()
		return

	# respawnea si estaba spawneado
	if has_spawned and spawned_item_id >= 0:
		for c in get_children():
			c.queue_free()
		_spawn_specific_item(spawned_item_id)

func _on_room_cleared() -> void:
	var room: Node = get_parent()
	if room != null and room.process_mode == Node.PROCESS_MODE_DISABLED:
		return

	if has_spawned or was_picked:
		return

	call_deferred("_spawn_item_deferred")

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

	var inst = ps.instantiate()
	add_child(inst)

	if inst.has_method("disable_hitbox"):
		inst.disable_hitbox()

	if inst is Node2D:
		(inst as Node2D).global_position = global_position

	await get_tree().create_timer(timer).timeout
	if inst != null and is_instance_valid(inst) and inst.has_method("enable_hitbox"):
		inst.enable_hitbox()

func mark_picked() -> void:
	was_picked = true
	for c in get_children():
		c.queue_free()

func is_activable() -> bool:
	return activable

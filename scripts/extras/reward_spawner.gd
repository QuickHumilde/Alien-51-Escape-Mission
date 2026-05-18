extends Node2D
class_name RewardSpawner

@export var activable: bool = true

@export var coin_percentage: float = 60.0
@export var health_percentage: float = 30.0
@export var mimic_chest_percentage: float = 10.0

var coin_scene: PackedScene = preload("res://scenes/pickup/coin.tscn")
var health_scene: PackedScene = preload("res://scenes/pickup/health.tscn")
var mimic_chest_scene: PackedScene = preload("res://scenes/pickup/mimic_chest.tscn")

var spawned: bool = false
var spawned_kind: String = "" # "coin" / "health" / "mimic"

func _ready() -> void:
	if !is_activable():
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	Signals.room_cleared.connect(_on_room_cleared)

# --- SAVE API (como ItemSpawner) ---

func get_spawner_key() -> String:
	return str(get_path())

func get_save_state() -> Dictionary:
	return {
		"spawned": spawned,
		"spawned_kind": spawned_kind,
	}

func load_save_state(state: Dictionary) -> void:
	spawned = bool(state.get("spawned", false))
	spawned_kind = str(state.get("spawned_kind", ""))

	if spawned and spawned_kind != "":
		_spawn_kind(spawned_kind)

# --- Core ---

func _on_room_cleared() -> void:
	var room: Node = get_parent()
	if room != null and room.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	if spawned:
		return

	var kind := _pick_weighted_kind()
	if kind == "":
		return

	spawned = true
	spawned_kind = kind
	_spawn_kind(kind)

func _spawn_kind(kind: String) -> void:
	var room := get_parent()
	if room == null:
		return

	var pickups := room.get_node_or_null("Pickups")
	if pickups == null:
		pickups = room

	# Evitar duplicados si load_save_state se llama más de una vez
	var desired_name := "Reward_" + kind
	for c in pickups.get_children():
		if c != null and c.name == desired_name:
			return

	var scene: PackedScene = null
	match kind:
		"coin":
			scene = coin_scene
		"health":
			scene = health_scene
		"mimic":
			scene = mimic_chest_scene
		_:
			scene = null

	if scene == null:
		return

	var inst := scene.instantiate()
	inst.name = desired_name
	pickups.add_child(inst)

	if inst is Node2D:
		(inst as Node2D).global_position = global_position

func _pick_weighted_kind() -> String:
	var coin_p = max(0.0, coin_percentage)
	var health_p = max(0.0, health_percentage)
	var mimic_p = max(0.0, mimic_chest_percentage)

	var total = coin_p + health_p + mimic_p
	if total <= 0.0:
		return ""

	var r = randf() * total
	if r < coin_p:
		return "coin"
	elif r < coin_p + health_p:
		return "health"
	else:
		return "mimic"

func is_activable() -> bool:
	return activable

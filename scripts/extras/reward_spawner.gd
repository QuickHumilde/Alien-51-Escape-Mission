extends Node2D

@export var activable: bool = true

@export var coin_percentage: float = 60.0
@export var health_percentage: float = 30.0
@export var mimic_chest_percentage: float = 10.0

var coin_scene: PackedScene = preload("res://scenes/pickup/coin.tscn")
var health_scene: PackedScene = preload("res://scenes/pickup/health.tscn")
var mimic_chest_scene: PackedScene = preload("res://scenes/pickup/mimic_chest.tscn")
var spawned: bool = false

func _ready() -> void:
	if !is_activable():
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		Signals.room_cleared.connect(_on_room_cleared)

func _on_room_cleared() -> void:
	var room: Node = get_parent()
	if room != null and room.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	if spawned:
		return

	var scene: PackedScene = _pick_weighted_scene()
	if scene == null:
		return

	var inst: Node= scene.instantiate()
	add_child(inst)
	spawned = true

func _pick_weighted_scene() -> PackedScene:
	var coin_p = max(0.0, coin_percentage)
	var health_p = max(0.0, health_percentage)
	var mimic_p = max(0.0, mimic_chest_percentage)

	var total = coin_p + health_p + mimic_p
	if total <= 0.0:
		return null

	var r = randf() * total

	if r < coin_p:
		return coin_scene
	elif r < coin_p + health_p:
		return health_scene
	else:
		return mimic_chest_scene

func is_activable() -> bool:
	return activable

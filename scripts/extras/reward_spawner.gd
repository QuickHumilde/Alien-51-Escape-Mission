extends Node2D

@export var activable: bool = true

@export var coin_percentage: float = 70.0
@export var health_percentage: float = 30.0

var coin_scene: PackedScene = preload("res://scenes/pickup/coin.tscn")
var health_scene: PackedScene = preload("res://scenes/pickup/health.tscn")
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
	var total = max(0.0, coin_percentage) + max(0.0, health_percentage)
	if total <= 0.0:
		return null

	var r = randf() * total
	if r < max(0.0, coin_percentage):
		return coin_scene
	return health_scene

func is_activable() -> bool:
	return activable

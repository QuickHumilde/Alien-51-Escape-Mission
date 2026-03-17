extends Node2D

@export var activable: bool = true
var coin_scene: PackedScene = preload("res://scenes/pickup/coin.tscn")
var spawned: bool = false

func _ready() -> void:
	if !is_activable():
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		Signals.room_cleared.connect(_on_room_cleared)

func _on_room_cleared() -> void:
	var room = get_parent()
	if room != null and room.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	if spawned:
		return
		
	var coin_instance := coin_scene.instantiate()
	add_child(coin_instance)
	spawned = true

func is_activable() -> bool:
	return activable

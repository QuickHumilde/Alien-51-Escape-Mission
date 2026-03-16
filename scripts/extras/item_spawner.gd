extends Node2D
class_name ItemSpawner

@export var use_global_random: bool = true

func _ready() -> void:
	call_deferred("_spawn_item_deferred")

func _spawn_item_deferred() -> void:
	if get_child_count() > 0:
		return

	if ItemManager.item_pool.is_empty():
		return

	var rng := GameManager.rng

	var item_id: int = ItemManager.pick_random_item_id(rng)
	if item_id < 0:
		return

	var ps: PackedScene = ItemManager.get_scene(item_id)
	if ps == null:
		return

	var inst := ps.instantiate()
	add_child(inst)

	if inst is Node2D:
		(inst as Node2D).global_position = global_position

	ItemManager.mark_removed(item_id)

extends Node2D
class_name ItemSpawner

@export var use_global_random: bool = true
@export var timer: float = 1.25

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

	if inst.has_method("disable_hitbox"):
		inst.disable_hitbox()

	inst.global_position = global_position

	ItemManager.mark_removed(item_id)

	await get_tree().create_timer(timer).timeout

	if inst != null and is_instance_valid(inst) and inst.has_method("enable_hitbox"):
		inst.enable_hitbox()

extends Node

var item_pool: Dictionary = {}

var removed_items: Array[int] = []

func _ready() -> void:
	register_item(1, preload("res://scenes/items/golden_fruit_item.tscn"))
	register_item(2, preload("res://scenes/items/weapons/piston_gun_item.tscn"))
	register_item(3, preload("res://scenes/items/weapons/blue_marker_weapon_item.tscn"))
	register_item(4, preload("res://scenes/items/ninja_headband_item.tscn"))
	register_item(5, preload("res://scenes/items/ant_man_helmet_item.tscn"))
	register_item(6, preload("res://scenes/items/business_glasses_item.tscn"))
	register_item(7, preload("res://scenes/items/dai_item.tscn"))
	register_item(8, preload("res://scenes/items/divisor_3_item.tscn"))
	register_item(9, preload("res://scenes/items/the_cross_item.tscn"))
	register_item(10, preload("res://scenes/items/ufo_item.tscn"))
	register_item(11, preload("res://scenes/items/dash_ability_item.tscn"))

func register_item(id: int, scene: PackedScene) -> void:
	item_pool[id] = scene

func reset_removed() -> void:
	removed_items.clear()

func pick_random_item_id(rng: RandomNumberGenerator) -> int:
	var candidates: Array[int] = []
	for id in item_pool.keys():
		var iid := int(id)
		if not removed_items.has(iid):
			candidates.append(iid)

	if candidates.is_empty():
		return -1

	return candidates[rng.randi_range(0, candidates.size() - 1)]

func get_scene(item_id: int) -> PackedScene:
	return item_pool.get(item_id, null) as PackedScene

func mark_removed(item_id: int) -> void:
	if item_id < 0:
		return
	if not removed_items.has(item_id):
		removed_items.append(item_id)

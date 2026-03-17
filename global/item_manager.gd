extends Node

var item_pool: Dictionary = {}
var removed_items: Array[int] = []

# item_id weapon_id
var item_to_weapon_id: Dictionary = {
	2: 2,
	3: 3,
}

func _ready() -> void:
	fill_item_pool()
	Signals.show_death_menu.connect(_on_death_menu)

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

func is_weapon_item(item_id: int) -> bool:
	return item_to_weapon_id.has(item_id)

func get_weapon_id_from_item(item_id: int) -> int:
	return int(item_to_weapon_id.get(item_id, -1))

func fill_item_pool():
	register_item(1, preload("res://scenes/items/golden_fruit_item.tscn"))
	register_item(2, preload("res://scenes/items/weapons/pistol_gun_item.tscn"))
	register_item(3, preload("res://scenes/items/weapons/blue_marker_weapon_item.tscn"))
	register_item(4, preload("res://scenes/items/ninja_headband_item.tscn"))
	register_item(5, preload("res://scenes/items/ant_man_helmet_item.tscn"))
	register_item(6, preload("res://scenes/items/business_glasses_item.tscn"))
	register_item(7, preload("res://scenes/items/dai_item.tscn"))
	register_item(8, preload("res://scenes/items/divisor_3_item.tscn"))
	register_item(9, preload("res://scenes/items/the_cross_item.tscn"))
	register_item(10, preload("res://scenes/items/ufo_item.tscn"))
	register_item(11, preload("res://scenes/items/dash_ability_item.tscn"))
	register_item(12, preload("res://scenes/items/weapons/continous_laser_weapon_item.tscn"))
	register_item(13, preload("res://scenes/items/heavy_armor_item.tscn"))
	register_item(14, preload("res://scenes/items/weapons/exploding_kittens_weapon_item.tscn"))

func clear_removed_items():
	removed_items.clear()

func _on_death_menu():
	clear_removed_items()

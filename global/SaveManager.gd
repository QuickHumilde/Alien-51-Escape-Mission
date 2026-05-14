extends Node

const SAVE_PATH := "user://run_save.json"
const SAVE_VERSION := 1

var _is_loading: bool = false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func reset_session_flags() -> void:
	_is_loading = false

# -----------------------
# Vector2 JSON helpers
# -----------------------

func _v2_to_json(v: Vector2) -> Dictionary:
	return {"x": v.x, "y": v.y}

func _json_to_v2(value: Variant, default_value: Vector2 = Vector2.ZERO) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return value

	if typeof(value) == TYPE_DICTIONARY:
		var d := value as Dictionary
		if d.has("x") and d.has("y"):
			return Vector2(float(d.get("x", default_value.x)), float(d.get("y", default_value.y)))

	if typeof(value) == TYPE_ARRAY:
		var a := value as Array
		if a.size() >= 2:
			return Vector2(float(a[0]), float(a[1]))

	if typeof(value) == TYPE_STRING:
		var s := (value as String).strip_edges()
		var parts := s.split(",", false)
		if parts.size() == 2:
			return Vector2(float(parts[0]), float(parts[1]))

	return default_value

# -----------------------
# Map serialization helpers
# -----------------------

func _serialize_map(raw_map: Dictionary) -> Dictionary:
	var out: Dictionary = {}

	for k in raw_map.keys():
		var room_any = raw_map.get(k)
		if typeof(room_any) != TYPE_DICTIONARY:
			continue

		var room: Dictionary = room_any as Dictionary
		var new_room: Dictionary = room.duplicate(true)

		if new_room.has("pos"):
			new_room["pos"] = _v2_to_json(_json_to_v2(new_room["pos"], Vector2.ZERO))

		out[str(k)] = new_room

	return out

func _deserialize_map(saved_map: Dictionary) -> Dictionary:
	var out: Dictionary = {}

	for k in saved_map.keys():
		var room_any = saved_map.get(k)
		if typeof(room_any) != TYPE_DICTIONARY:
			continue

		var room: Dictionary = room_any as Dictionary
		var new_room: Dictionary = room.duplicate(true)

		if new_room.has("pos"):
			new_room["pos"] = _json_to_v2(new_room["pos"], Vector2.ZERO)

		out[str(k)] = new_room

	return out

# -----------------------
# Inventory reconstruction (modifiers from picked items)
# -----------------------

func _cleanup_existing_modifiers(player: Character) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.inventory == null or not is_instance_valid(player.inventory):
		return

	var mods_copy: Array = player.inventory.modifiers.duplicate(false)
	for m in mods_copy:
		if m == null:
			continue
		if not is_instance_valid(m):
			continue
		if m.has_method("destroy"):
			m.call("destroy")
		m.queue_free()

	player.inventory.modifiers.clear()

func _rebuild_inventory_from_picked_items(player: Character, picked_ids: Array[int]) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.inventory == null or not is_instance_valid(player.inventory):
		return

	_cleanup_existing_modifiers(player)

	for id in picked_ids:
		var item_id := int(id)
		var ps: PackedScene = ItemManager.get_scene(item_id)
		if ps == null:
			continue

		var inst := ps.instantiate()
		if inst == null:
			continue

		if is_instance_valid(inst) and inst.has_method("give_changes"):
			inst.call("give_changes", player)

		if is_instance_valid(inst):
			inst.queue_free()

	if player.stats != null and is_instance_valid(player.stats):
		player.stats._invalidate_stats()
		player.stats.recalc_stats()

# -----------------------
# Abilities save/load (FIX)
# -----------------------

func _serialize_ability(player: Character) -> Dictionary:
	# Guarda la habilidad actual, aunque sea un script (.gd), usando su resource_path.
	# También guarda state opcional (cooldown etc).
	var out := {
		"resource_path": "",
		"state": {},
	}

	if player == null or not is_instance_valid(player):
		return out
	if player.abilities == null or not is_instance_valid(player.abilities):
		return out
	if player.abilities.abilities.is_empty():
		return out

	var ab = player.abilities.abilities[player.abilities.actual_ability_index]
	if ab == null or not is_instance_valid(ab):
		return out

	# OJO: DashAbility es un Node con script. Aquí podemos guardar script.resource_path
	if ab is Node:
		var script = (ab as Node).get_script()
		if script != null:
			out.resource_path = str(script.resource_path)

	# Estado opcional
	if ab.has_method("get_save_state"):
		out.state = ab.call("get_save_state") as Dictionary

	return out

func _deserialize_ability(player: Character, ability_data: Dictionary) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.abilities == null or not is_instance_valid(player.abilities):
		return

	var res_path := str(ability_data.get("resource_path", ""))
	if res_path.is_empty():
		player.abilities.remove_current_ability()
		return

	var scr := load(res_path)
	if scr == null:
		player.abilities.remove_current_ability()
		return

	var ab: Node = null

	var probe := Node.new()
	probe.set_script(scr)
	if probe != null and probe.has_method("get_ability_scene_path"):
		var scene_path := str(probe.call("get_ability_scene_path"))
		if not scene_path.is_empty():
			var ps: PackedScene = load(scene_path)
			if ps != null:
				ab = ps.instantiate()
	probe.queue_free()

	if ab == null:
		ab = Node.new()
		ab.set_script(scr)

	if ab.has_method("get_player"):
		ab.call("get_player", player)

	var st: Dictionary = ability_data.get("state", {}) as Dictionary
	if not st.is_empty() and ab.has_method("load_save_state"):
		ab.call("load_save_state", st)

	player.abilities.change_ability(ab, Vector2.ZERO, false)
	
# -----------------------
# Save / Load
# -----------------------

func save_run(dungeon: Node, player: Character, minimap: Node, room_type: String = "") -> void:
	if dungeon == null or player == null:
		return

	var data := {
		"version": SAVE_VERSION,
		"timestamp_unix": Time.get_unix_time_from_system(),

		"game": {
			"current_floor": GameManager.current_floor,
			"game_time_scale": GameManager.game_time_scale,
			"seed_value": GameManager.seed_value,
			"rng_state": GameManager.rng.state,
			"used_bosses": GameManager.used_bosses,
		},

		"items": {
			"removed_items": ItemManager.removed_items,
		},

		"dungeon": {
			"map": _serialize_map(dungeon.map),
			"current_room_pos": _v2_to_json(dungeon.current_room_pos),
		},

		"minimap": {
			"visited": minimap.visited if minimap != null and "visited" in minimap else {},
			"last_floor_id": GameManager.current_floor,
		},

		"player": {
			"global_position": _v2_to_json(player.global_position),

			"stats": {
				"max_health": player.stats.max_health,
				"health": player.stats.health,
				"extra_health": player.stats.extra_health,
				"speed": player.stats.speed,
				"size": player.stats.size,
				"extra_damage": player.stats.extra_damage,
				"extra_lifetime": player.stats.extra_lifetime,
				"invulnerability_time": player.stats.invulnerability_time,
				"is_flying": player.stats.is_flying,
				"revives": player.stats.revives,
			},

			"inventory": {
				"money": player.inventory.money,
				"items_count": player.inventory.items,
				"picked_item_ids": player.inventory.picked_item_ids if "picked_item_ids" in player.inventory else [],
			},

			"combat": {
				"weapon_order": player.combat.weapon_order,
				"current_weapon_index": player.combat.current_weapon_index,
			},

			# FIX: guarda habilidad por script resource_path + state
			"ability": _serialize_ability(player),
		},

		"audio": {
			"floor_music_name": AudioManager._floor_music_name,
			"in_shop": AudioManager.in_shop,
			"in_boss": AudioManager.in_boss,
			"room_type": room_type,
		}
	}

	var json := JSON.stringify(data)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(json)

func load_run(dungeon: Node, player: Character, minimap: Node) -> bool:
	if _is_loading:
		return false
	_is_loading = true

	if not has_save():
		_is_loading = false
		return false

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		_is_loading = false
		return false

	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_is_loading = false
		return false
	var data: Dictionary = parsed

	if int(data.get("version", 0)) != SAVE_VERSION:
		_is_loading = false
		return false

	# --- GAME ---
	var g: Dictionary = data.get("game", {})
	GameManager.current_floor = int(g.get("current_floor", 1))
	GameManager.game_time_scale = float(g.get("game_time_scale", 1.0))
	GameManager.seed_value = int(g.get("seed_value", -1))
	GameManager.generate_seed()

	if g.has("rng_state"):
		GameManager.rng.state = int(g.get("rng_state"))

	GameManager.used_bosses.clear()
	var raw_used = g.get("used_bosses", [])
	if typeof(raw_used) == TYPE_ARRAY:
		for v in raw_used:
			GameManager.used_bosses.append(str(v))

	# --- ITEM POOL ---
	var it: Dictionary = data.get("items", {})

	ItemManager.removed_items.clear()
	var raw_removed = it.get("removed_items", [])
	if typeof(raw_removed) == TYPE_ARRAY:
		for v in raw_removed:
			ItemManager.removed_items.append(int(v))

	# --- DUNGEON ---
	var d: Dictionary = data.get("dungeon", {})
	dungeon.map = _deserialize_map(d.get("map", {}) as Dictionary)
	dungeon.current_room_pos = _json_to_v2(d.get("current_room_pos"), Vector2.ZERO)

	# --- MINIMAP ---
	var mm: Dictionary = data.get("minimap", {})
	if minimap != null and "visited" in minimap:
		minimap.visited = mm.get("visited", {}) as Dictionary
		minimap._last_floor_id = int(mm.get("last_floor_id", GameManager.current_floor))

	# --- PLAYER ---
	var p: Dictionary = data.get("player", {})

	# inventory first
	var inv: Dictionary = p.get("inventory", {})
	player.inventory.money = int(inv.get("money", player.inventory.money))
	player.inventory.items = int(inv.get("items_count", player.inventory.items))

	var picked_ids: Array[int] = []
	if "picked_item_ids" in player.inventory:
		player.inventory.picked_item_ids.clear()
		var raw_picked = inv.get("picked_item_ids", [])
		if typeof(raw_picked) == TYPE_ARRAY:
			for v in raw_picked:
				var iid := int(v)
				player.inventory.picked_item_ids.append(iid)
				picked_ids.append(iid)

	Signals.money_changed.emit(player.inventory.money)

	# modifiers por items (sin tocar abilities aquí)
	_rebuild_inventory_from_picked_items(player, picked_ids)

	# stats base
	var s: Dictionary = p.get("stats", {})
	player.stats.max_health = float(s.get("max_health", player.stats.max_health))
	player.stats.health = float(s.get("health", player.stats.health))
	player.stats.extra_health = float(s.get("extra_health", player.stats.extra_health))
	player.stats.speed = float(s.get("speed", player.stats.speed))
	player.stats.size = float(s.get("size", player.stats.size))
	player.stats.extra_damage = float(s.get("extra_damage", player.stats.extra_damage))
	player.stats.extra_lifetime = float(s.get("extra_lifetime", player.stats.extra_lifetime))
	player.stats.invulnerability_time = float(s.get("invulnerability_time", player.stats.invulnerability_time))
	player.stats.is_flying = bool(s.get("is_flying", player.stats.is_flying))
	player.stats.revives = int(s.get("revives", player.stats.revives))
	player.stats._invalidate_stats()
	player.stats.recalc_stats()
	Signals.health_changed.emit(player.stats.health, player.stats.max_health, player.stats.extra_health, player.stats.get_revives())

	# combat
	var c: Dictionary = p.get("combat", {})
	player.combat.weapon_order.clear()
	var raw_order = c.get("weapon_order", [1])
	if typeof(raw_order) == TYPE_ARRAY:
		for v in raw_order:
			player.combat.weapon_order.append(int(v))
	else:
		player.combat.weapon_order.append(1)

	player.combat.current_weapon_index = int(c.get("current_weapon_index", 0))
	if player.combat.current_weapon_index < 0:
		player.combat.current_weapon_index = 0
	if player.combat.current_weapon_index >= player.combat.weapon_order.size():
		player.combat.current_weapon_index = 0

	if not player.combat.weapon_order.is_empty():
		player.combat.equip_weapon(int(player.combat.weapon_order[player.combat.current_weapon_index]))

	# FIX: habilidad al final, desde el save
	var ability_data: Dictionary = p.get("ability", {}) as Dictionary
	_deserialize_ability(player, ability_data)

	# player position
	player.global_position = _json_to_v2(p.get("global_position"), player.global_position)

	# minimap redraw
	if minimap != null and minimap.has_method("set_data"):
		minimap.call("set_data", dungeon.map, dungeon.current_room_pos, GameManager.get_current_floor())

	# audio
	var a: Dictionary = data.get("audio", {})
	AudioManager._floor_music_name = str(a.get("floor_music_name", ""))
	var room_type := str(a.get("room_type", ""))
	if room_type == "shop":
		AudioManager._enter_shop_music()
	elif room_type == "boss":
		AudioManager._enter_boss_music()
	elif AudioManager._floor_music_name != "":
		AudioManager.play_music(AudioManager._floor_music_name, true, -20.0)
	else:
		AudioManager.play_floor_music()

	_is_loading = false
	return true

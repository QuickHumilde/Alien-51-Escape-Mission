extends Node2D

@export var room_slot_size: Vector2 = Vector2(640, 384)
@export var transition_duration: float = 0.35

var rng: RandomNumberGenerator

@onready var player: CharacterBody2D = $Player as CharacterBody2D
@onready var cam: Camera2D = $Camera2D as Camera2D
@onready var world: Node2D = $World as Node2D
@onready var minimap: Control = $CanvasLayer/MinimapFrame/Minimap

@export var min_rooms: int = 5
@export var max_rooms: int = 8
@export var num_item_rooms: int = 2
@export var num_shop_rooms: int = 1
@export var boss_min_manhattan_distance_from_start: int = 3

const FLOOR_SETTINGS := [
	{"min_rooms": 5,  "max_rooms": 8,  "item_rooms": 2, "shop_rooms": 1, "boss_dist": 3},
	{"min_rooms": 8,  "max_rooms": 12, "item_rooms": 2, "shop_rooms": 1, "boss_dist": 3},
	{"min_rooms": 12, "max_rooms": 16, "item_rooms": 2, "shop_rooms": 1, "boss_dist": 4},
]

var room_scenes: Dictionary = {
	"start": [ preload("res://scenes/rooms/start/start_room_1.tscn") ],
	"normal": [
	preload("res://scenes/rooms/normal/normal_room_1.tscn"),
	preload("res://scenes/rooms/normal/normal_room_2.tscn"),
	preload("res://scenes/rooms/normal/normal_room_3.tscn"),
	preload("res://scenes/rooms/normal/normal_room_4.tscn"),
	preload("res://scenes/rooms/normal/normal_room_5.tscn"),
	preload("res://scenes/rooms/normal/normal_room_6.tscn"),
	preload("res://scenes/rooms/normal/normal_room_7.tscn"),
	preload("res://scenes/rooms/normal/normal_room_8.tscn"),
	preload("res://scenes/rooms/normal/normal_room_9.tscn"),
	],
	"item": [ preload("res://scenes/rooms/item/item_room_1.tscn") ],
	"shop": [ preload("res://scenes/rooms/shop/shop_room_1.tscn") ],
	"boss": [ preload("res://scenes/rooms/boss/boss_room_1.tscn") ]
}

var map: Dictionary = {}
var main_path_rooms: Array[Vector2] = []
var room_instances: Dictionary = {}
var current_room_pos: Vector2 = Vector2.ZERO
var current_room: Node2D = null
var transitioning: bool = false

var _door_caps_cache: Dictionary = {}

func _ready() -> void:
	GameManager.generate_seed()
	rng = GameManager.rng
	_apply_floor_settings()
	generate_map()
	_print_map_type_counts()

	current_room_pos = Vector2.ZERO
	current_room = await _spawn_room_at(current_room_pos)
	_snap_camera_to_room(current_room)
	_place_player(current_room, "")

	if minimap != null and minimap.has_method("set_data"):
		minimap.call("set_data", map, current_room_pos)

	print("Seed usada: ", GameManager.seed_value)

	_watch_room_cleared(current_room)

	AudioManager.play_floor_music()
	_emit_room_changed()

func next_floor() -> void:
	if transitioning:
		return
	transitioning = true

	GameManager.next_floor()

	for child in world.get_children():
		child.queue_free()

	room_instances.clear()
	_apply_floor_settings()
	generate_map()
	_print_map_type_counts()

	current_room_pos = Vector2.ZERO
	current_room = await _spawn_room_at(current_room_pos)
	_snap_camera_to_room(current_room)
	_place_player(current_room, "")

	if minimap != null and minimap.has_method("set_data"):
		minimap.call("set_data", map, current_room_pos)

	_watch_room_cleared(current_room)

	Signals.floor_changed.emit()

	AudioManager.play_floor_music()
	_emit_room_changed()

	transitioning = false

func _emit_room_changed() -> void:
	var key := pos_to_key(current_room_pos)
	if not map.has(key):
		return
	var data := map[key] as Dictionary
	var room_type := str(data.get("type", "normal"))
	Signals.room_changed.emit(room_type)

func _apply_floor_settings() -> void:
	var f: int = int(GameManager.get_current_floor())
	if f < 1:
		f = 1
	var idx: int = int(clamp(f - 1, 0, FLOOR_SETTINGS.size() - 1))
	var s: Dictionary = FLOOR_SETTINGS[idx]
	min_rooms = int(s.get("min_rooms", min_rooms))
	max_rooms = int(s.get("max_rooms", max_rooms))
	num_item_rooms = int(s.get("item_rooms", num_item_rooms))
	num_shop_rooms = int(s.get("shop_rooms", num_shop_rooms))
	boss_min_manhattan_distance_from_start = int(s.get("boss_dist", boss_min_manhattan_distance_from_start))

func _print_map_type_counts() -> void:
	var counts: Dictionary = {"start":0, "normal":0, "item":0, "shop":0, "boss":0}
	for k in map.keys():
		var t := str((map[k] as Dictionary).get("type", "normal"))
		if not counts.has(t):
			counts[t] = 0
		counts[t] += 1

func _spawn_room_at(room_pos: Vector2) -> Node2D:
	var key: String = pos_to_key(room_pos)
	if room_instances.has(key) and is_instance_valid(room_instances[key]):
		var existing: Node2D = room_instances[key] as Node2D
		existing.visible = true
		existing.process_mode = Node.PROCESS_MODE_INHERIT
		return existing

	var data: Dictionary = map[key] as Dictionary
	var room: Node2D = _instantiate_room_for(data)
	world.add_child(room)
	room.position = room_pos * room_slot_size
	room_instances[key] = room

	if room.has_signal("door_entered"):
		room.connect("door_entered", Callable(self, "_on_door_entered"))
	if room.has_method("setup"):
		room.call_deferred("setup", data)

	await get_tree().process_frame
	return room

func _instantiate_room_for(data: Dictionary) -> Node2D:
	if data.has("scene_path"):
		var p: String = str(data["scene_path"])
		var ps: PackedScene = load(p) as PackedScene
		if ps != null:
			return ps.instantiate() as Node2D

	var room_type: String = str(data.get("type", "normal"))
	var list_any: Variant = room_scenes.get(room_type, room_scenes["normal"])
	var list: Array = list_any as Array
	var scene_any: Variant = list[rng.randi_range(0, list.size() - 1)]
	var scene: PackedScene = scene_any as PackedScene
	return scene.instantiate() as Node2D

func _on_door_entered(dir: String) -> void:
	if transitioning:
		return

	var d: String = dir.strip_edges().to_lower()
	var step := dir_to_vector(d)
	var next_pos: Vector2 = current_room_pos + step
	if not map.has(pos_to_key(next_pos)):
		return

	transitioning = true
	call_deferred("_start_transition_deferred", next_pos, d)

func _start_transition_deferred(next_pos: Vector2, exit_dir: String) -> void:
	await _transition_to(next_pos, exit_dir)

func _transition_to(next_pos: Vector2, exit_dir: String) -> void:
	var prev_room: Node2D = current_room
	var next_room: Node2D = await _spawn_room_at(next_pos)

	if is_instance_valid(prev_room):
		prev_room.visible = false
		prev_room.process_mode = Node.PROCESS_MODE_DISABLED

	next_room.visible = true
	next_room.process_mode = Node.PROCESS_MODE_INHERIT

	_place_player(next_room, opposite_dir(exit_dir))
	await get_tree().process_frame

	var from_cam: Vector2 = _room_center_node(prev_room)
	var to_cam: Vector2 = _room_center_node(next_room)
	await _slide_camera(from_cam, to_cam, transition_duration)

	current_room = next_room
	current_room_pos = next_pos

	if minimap != null and minimap.has_method("set_data"):
		minimap.call("set_data", map, current_room_pos)

	transitioning = false

	_emit_room_changed()
	_watch_room_cleared(current_room)

func _place_player(room: Node2D, entered_from_dir: String) -> void:
	if room.has_method("get_spawn_global"):
		player.global_position = room.call("get_spawn_global", entered_from_dir) as Vector2
	else:
		player.global_position = room.global_position

func _snap_camera_to_room(room: Node2D) -> void:
	cam.global_position = _room_center_node(room)

func _room_center_node(room: Node2D) -> Vector2:
	if room != null and room.has_method("get_center_global"):
		return room.call("get_center_global") as Vector2
	return room.global_position

func _slide_camera(from_pos: Vector2, to_pos: Vector2, duration: float) -> void:
	var t: float = 0.0
	while t < duration:
		t += get_process_delta_time()
		var a: float = clamp(t / duration, 0.0, 1.0)
		a = a * a * (3.0 - 2.0 * a)
		cam.global_position = from_pos.lerp(to_pos, a)
		await get_tree().process_frame
	cam.global_position = to_pos

func rand_range(a: int, b: int) -> int: return rng.randi_range(a, b)
func rand_choice(array: Array) -> Variant: return array[rand_range(0, array.size() - 1)]

func shuffle_seeded(array: Array) -> void:
	for i in range(array.size()):
		var j: int = rng.randi_range(0, array.size() - 1)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp

func create_room(pos: Vector2, type: String, doors: Dictionary, scene_path: String) -> Dictionary:
	return {
		"pos": pos,
		"type": type,
		"doors": doors,
		"scene_path": scene_path,
		"cleared": false,
		"had_enemies": false
	}

func _room_key() -> String:
	return pos_to_key(current_room_pos)

func _room_data() -> Dictionary:
	var key := _room_key()
	if not map.has(key):
		return {}
	return map[key] as Dictionary

func _set_room_flag(flag: String, value: bool) -> void:
	var key := _room_key()
	if not map.has(key):
		return
	(map[key] as Dictionary)[flag] = value


func init_doors(value: bool) -> Dictionary:
	return {"up": value, "down": value, "left": value, "right": value}

func pos_to_key(pos: Vector2) -> String:
	return str(pos.x) + "," + str(pos.y)

func dir_to_vector(dir: String) -> Vector2:
	match dir:
		"up": return Vector2(0, -1)
		"down": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
		_: return Vector2.ZERO

func opposite_dir(dir: String) -> String:
	match dir:
		"up": return "down"
		"down": return "up"
		"left": return "right"
		"right": return "left"
	return ""

func _get_room_data_at(pos: Vector2) -> Dictionary:
	var key := pos_to_key(pos)
	if not map.has(key):
		return {}
	return map[key] as Dictionary

func _is_room_cleared(pos: Vector2) -> bool:
	var data := _get_room_data_at(pos)
	return bool(data.get("cleared", false))

func _set_room_cleared(pos: Vector2, value: bool) -> void:
	var key := pos_to_key(pos)
	if not map.has(key):
		return
	(map[key] as Dictionary)["cleared"] = value

func manhattan(a: Vector2, b: Vector2) -> int:
	return int(abs(a.x - b.x) + abs(a.y - b.y))

func get_scene_door_caps(scene: PackedScene) -> Dictionary:
	if scene != null and not scene.resource_path.is_empty():
		if _door_caps_cache.has(scene.resource_path):
			return _door_caps_cache[scene.resource_path] as Dictionary

	var inst := scene.instantiate()
	var caps := {"up": true, "down": true, "left": true, "right": true}
	if inst != null and inst.has_method("get_door_caps"):
		caps = inst.call("get_door_caps")
	if inst != null:
		inst.queue_free()

	if scene != null and not scene.resource_path.is_empty():
		_door_caps_cache[scene.resource_path] = caps

	return caps

func _get_caps_from_scene_path(scene_path: String) -> Dictionary:
	if _door_caps_cache.has(scene_path):
		return _door_caps_cache[scene_path] as Dictionary
	var ps := load(scene_path) as PackedScene
	if ps == null:
		var fallback := {"up": true, "down": true, "left": true, "right": true}
		_door_caps_cache[scene_path] = fallback
		return fallback
	var caps := get_scene_door_caps(ps)
	_door_caps_cache[scene_path] = caps
	return caps

func _room_allows_exit(base_data: Dictionary, dir: String) -> bool:
	if not base_data.has("scene_path"):
		return true
	var p := str(base_data.get("scene_path", ""))
	if p.is_empty():
		return true
	var caps := _get_caps_from_scene_path(p)
	return bool(caps.get(dir, true))

func pick_scene_with_required_door(room_type: String, required_entry_dir: String) -> PackedScene:
	var list_any: Variant = room_scenes.get(room_type, room_scenes["normal"])
	var list: Array = list_any as Array
	var candidates: Array = []
	for s in list:
		candidates.append(s)
	shuffle_seeded(candidates)
	for s in candidates:
		var ps := s as PackedScene
		var caps := get_scene_door_caps(ps)
		if bool(caps.get(required_entry_dir, true)):
			return ps
	return null

func _has_room_type(t: String) -> bool:
	for k in map.keys():
		var data := map[k] as Dictionary
		if str(data.get("type", "")) == t:
			return true
	return false

func generate_map() -> void:
	var tries := 0
	while true:
		tries += 1
		map.clear()
		main_path_rooms.clear()
		room_instances.clear()

		var start_pos := Vector2.ZERO
		var start_scene: PackedScene = room_scenes["start"][0]
		map[pos_to_key(start_pos)] = create_room(start_pos, "start", init_doors(false), start_scene.resource_path)
		main_path_rooms.append(start_pos)

		_create_start_item_branch(start_pos)
		var target_normals: int = rand_range(min_rooms, max_rooms)
		_create_main_normals(start_pos, target_normals)
		_create_extra_item_branches(start_pos, num_item_rooms - 1)
		_create_shop_branches(num_shop_rooms)
		_create_boss_branch(start_pos)
		_cleanup_doors_against_missing_neighbors()

		if _has_room_type("boss"):
			break
		if tries >= 30:
			push_error("No se pudo generar una sala de boss tras " + str(tries) + " intentos.")
			break

func _create_start_item_branch(start_pos: Vector2) -> void:
	if num_item_rooms <= 0:
		return
	var dirs: Array[String] = ["up","down","left","right"]
	shuffle_seeded(dirs)
	var start_key := pos_to_key(start_pos)
	var start_data := map[start_key] as Dictionary
	var start_scene: PackedScene = load(str(start_data["scene_path"])) as PackedScene
	var start_caps := get_scene_door_caps(start_scene)

	for d in dirs:
		if not bool(start_caps.get(d, true)):
			continue

		var new_pos := start_pos + dir_to_vector(d)
		if map.has(pos_to_key(new_pos)):
			continue

		var item_scene := pick_scene_with_required_door("item", opposite_dir(d))
		if item_scene == null:
			continue

		var item_doors := init_doors(false)
		item_doors[opposite_dir(d)] = true
		map[pos_to_key(new_pos)] = create_room(new_pos, "item", item_doors, item_scene.resource_path)
		(start_data["doors"] as Dictionary)[d] = true
		return

func _create_main_normals(_start_pos: Vector2, target_normals: int) -> void:
	var normals_created := 0
	var attempts := 0
	while normals_created < target_normals and attempts < target_normals * 200:
		attempts += 1
		var base_pos: Vector2 = rand_choice(main_path_rooms) as Vector2
		var base_key := pos_to_key(base_pos)
		var base_data := map[base_key] as Dictionary

		var dirs: Array[String] = ["up","down","left","right"]
		shuffle_seeded(dirs)

		for d in dirs:
			if not _room_allows_exit(base_data, d):
				continue

			var new_pos := base_pos + dir_to_vector(d)
			if map.has(pos_to_key(new_pos)):
				continue

			var normal_scene := pick_scene_with_required_door("normal", opposite_dir(d))
			if normal_scene == null:
				continue

			var new_doors := init_doors(false)
			map[pos_to_key(new_pos)] = create_room(new_pos, "normal", new_doors, normal_scene.resource_path)
			(base_data["doors"] as Dictionary)[d] = true
			(new_doors as Dictionary)[opposite_dir(d)] = true
			main_path_rooms.append(new_pos)
			normals_created += 1
			break

func _create_extra_item_branches(_start_pos: Vector2, count: int) -> void:
	for i in range(max(0, count)):
		if not _create_dead_end_branch("item", Vector2.ZERO, 25):
			print("No se pudieron crear todas las salas de item")

func _create_shop_branches(count: int) -> void:
	for i in range(max(0, count)):
		if not _create_dead_end_branch("shop", Vector2.ZERO, 25):
			print("No se pudieron crear todas las tiendas")

func _create_boss_branch(start_pos: Vector2) -> void:
	var bases: Array[Vector2] = []
	for p in main_path_rooms:
		if manhattan(p, start_pos) >= boss_min_manhattan_distance_from_start:
			bases.append(p)
	if bases.is_empty():
		for p2 in main_path_rooms:
			if p2 != start_pos:
				bases.append(p2)
	if bases.is_empty():
		return
	shuffle_seeded(bases)
	for base in bases:
		if _create_dead_end_branch("boss", base, 50):
			return

func _create_dead_end_branch(room_type: String, preferred_base: Vector2, max_attempts: int) -> bool:
	var start_pos := Vector2.ZERO
	for attempt in range(max_attempts):
		var base_pos: Vector2 = preferred_base
		if base_pos == Vector2.ZERO:
			base_pos = rand_choice(main_path_rooms) as Vector2
		if room_type != "item" and base_pos == start_pos:
			continue

		var base_key := pos_to_key(base_pos)
		var base_data := map[base_key] as Dictionary

		var dirs: Array[String] = ["up","down","left","right"]
		shuffle_seeded(dirs)

		for d in dirs:
			if not _room_allows_exit(base_data, d):
				continue

			var new_pos := base_pos + dir_to_vector(d)
			if map.has(pos_to_key(new_pos)):
				continue

			var special_scene := pick_scene_with_required_door(room_type, opposite_dir(d))
			if special_scene == null:
				continue

			var doors := init_doors(false)
			doors[opposite_dir(d)] = true
			map[pos_to_key(new_pos)] = create_room(new_pos, room_type, doors, special_scene.resource_path)
			(base_data["doors"] as Dictionary)[d] = true
			return true
	return false

func _cleanup_doors_against_missing_neighbors() -> void:
	for k in map.keys():
		var data := map[k] as Dictionary
		var p: Vector2 = data.get("pos", Vector2.ZERO)
		var doors: Dictionary = data.get("doors", {})
		for d in ["up","down","left","right"]:
			if not bool(doors.get(d, false)):
				continue
			var np := p + dir_to_vector(d)
			if not map.has(pos_to_key(np)):
				doors[d] = false

func _watch_room_cleared(room: Node) -> void:
	var data := _room_data()
	if data.is_empty():
		return
	if bool(data.get("cleared", false)):
		return

	var enemies := room.get_node_or_null("Enemies")
	if enemies == null:
		return

	var found_enemy := false
	for e in enemies.get_children():
		if e.is_in_group("enemy"):
			found_enemy = true
			var cb := _on_enemy_exited.bind(room)
			if not e.tree_exited.is_connected(cb):
				e.tree_exited.connect(cb)

	if not found_enemy:
		return

	_set_room_flag("had_enemies", true)

func _is_enemies_empty(enemies: Node) -> bool:
	for e in enemies.get_children():
		if e.is_in_group("enemy"):
			return false
	return true

func _on_enemy_exited(room: Node) -> void:
	if room != current_room:
		return

	var key := _room_key()
	if not map.has(key):
		return
	var data := map[key] as Dictionary

	if bool(data.get("cleared", false)):
		return
	if not bool(data.get("had_enemies", false)):
		return

	var enemies := room.get_node_or_null("Enemies")
	if enemies == null:
		return

	for e in enemies.get_children():
		if e.is_in_group("enemy"):
			return

	data["cleared"] = true
	Signals.room_cleared.emit()

func _emit_room_cleared_if_empty(enemies: Node) -> void:
	for e in enemies.get_children():
		if e.is_in_group("enemy"):
			return
	Signals.room_cleared.emit()

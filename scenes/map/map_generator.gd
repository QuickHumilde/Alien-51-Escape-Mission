extends Node2D

@export var room_slot_size: Vector2 = Vector2(640, 384)
@export var transition_duration: float = 0.35

@export var seed_value: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var player: CharacterBody2D = $Player as CharacterBody2D
@onready var cam: Camera2D = $Camera2D as Camera2D
@onready var world: Node2D = $World as Node2D
@onready var minimap: Control = $CanvasLayer/MinimapFrame/Minimap

@export var min_rooms: int = 12
@export var max_rooms: int = 24

@export var num_item_rooms: int = 2
@export var num_shop_rooms: int = 2
@export var boss_min_manhattan_distance_from_start: int = 3

var room_scenes: Dictionary = {
	"start": [ preload("res://scenes/rooms/start/start_room_1.tscn") ],
	"normal": [ preload("res://scenes/rooms/normal/normal_room_1.tscn") ],
	"item": [ preload("res://scenes/rooms/item/item_room_1.tscn") ],
	"shop": [ preload("res://scenes/rooms/shop/shop_room_1.tscn") ],
	"boss": [ preload("res://scenes/rooms/boss/boss_room_1.tscn") ]
}

var map: Dictionary = {}
var main_path_rooms: Array[Vector2] = []

# Opción A: cachear instancias de salas (NO queue_free)
var room_instances: Dictionary = {} # key(String "x,y") -> Node2D

var current_room_pos: Vector2 = Vector2.ZERO
var current_room: Node2D = null
var transitioning: bool = false

func _ready() -> void:
	if seed_value == 0:
		seed_value = randi()
	rng.seed = seed_value

	generate_map()
	_print_map_type_counts()

	current_room_pos = Vector2.ZERO
	current_room = await _spawn_room_at(current_room_pos)
	_snap_camera_to_room(current_room)
	_place_player(current_room, "")

	if minimap != null and minimap.has_method("set_data"):
		minimap.call("set_data", map, current_room_pos)

	print("Seed usada: ", seed_value)

func _print_map_type_counts() -> void:
	var counts := {"start":0, "normal":0, "item":0, "shop":0, "boss":0}
	for k in map.keys():
		var t := str((map[k] as Dictionary).get("type", "normal"))
		if not counts.has(t):
			counts[t] = 0
		counts[t] += 1

# ----------------- Spawn / transition -----------------

func _spawn_room_at(room_pos: Vector2) -> Node2D:
	var key: String = pos_to_key(room_pos)

	# Reusar sala si ya existe (persistencia de enemigos/items/etc)
	if room_instances.has(key) and is_instance_valid(room_instances[key]):
		var existing: Node2D = room_instances[key] as Node2D
		existing.visible = true
		existing.process_mode = Node.PROCESS_MODE_INHERIT
		return existing

	# Crear nueva
	var data: Dictionary = map[key] as Dictionary
	var room: Node2D = _instantiate_room_for(data)
	world.add_child(room)
	room.position = room_pos * room_slot_size
	room_instances[key] = room

	if room.has_signal("door_entered"):
		room.connect("door_entered", Callable(self, "_on_door_entered"))

	await get_tree().process_frame

	if room.has_method("setup"):
		room.call("setup", data)

	await get_tree().process_frame
	return room

func _instantiate_room_for(data: Dictionary) -> Node2D:
	if data.has("scene_path"):
		var p := str(data["scene_path"])
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
	# ya está transitioning=true desde _on_door_entered

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

# ----------------- Generator helpers -----------------

func rand_range(a: int, b: int) -> int: return rng.randi_range(a, b)
func rand_choice(array: Array) -> Variant: return array[rand_range(0, array.size() - 1)]

func shuffle_seeded(array: Array) -> void:
	for i in range(array.size()):
		var j: int = rng.randi_range(0, array.size() - 1)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp

func create_room(pos: Vector2, type: String, doors: Dictionary, scene_path: String) -> Dictionary:
	return {"pos": pos, "type": type, "doors": doors, "scene_path": scene_path}

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

func manhattan(a: Vector2, b: Vector2) -> int:
	return int(abs(a.x - b.x) + abs(a.y - b.y))

func get_scene_door_caps(scene: PackedScene) -> Dictionary:
	var inst := scene.instantiate()
	var caps := {"up": true, "down": true, "left": true, "right": true}
	if inst != null and inst.has_method("get_door_caps"):
		caps = inst.call("get_door_caps")
	if inst != null:
		inst.queue_free()
	return caps

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

# ----------------- MAP GENERATION -----------------

func generate_map() -> void:
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
		var new_pos := start_pos + dir_to_vector(d)
		if map.has(pos_to_key(new_pos)):
			continue

		if not bool(start_caps.get(d, true)):
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

extends Node2D

const ROOM_SIZE = Vector2(512, 512) # Tamaño en píxeles de cada sala
const LOAD_RADIUS = 2               # Cuántas salas alrededor cargar

# Configuración del mapa
var min_rooms = 12
var max_rooms = 24
var num_item_rooms = 2
var num_shop_rooms = 2

@export var seed_value: int
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Diccionario de escenas por tipo
var room_scenes = {
	"start": [ preload("res://scenes/rooms/start/start_room_1.tscn") ],
	"normal": [
		preload("res://scenes/rooms/normal/normal_room_1.tscn"),
	],
	"item": [ preload("res://scenes/rooms/item/item_room_1.tscn") ],
	"shop": [ preload("res://scenes/rooms/shop/shop_room_1.tscn") ],
	"boss": [ preload("res://scenes/rooms/boss/boss_room_1.tscn") ]
}

# Datos del mapa
var map = {}              # key = "x,y", value = room data
var main_path_rooms = []  # posiciones Vector2
var room_instances = {}   # instancias cargadas

# Minimap
var minimap_data = {}

func _ready():
	seed_value = randi()
	rng.seed = seed_value

	generate_map()
	load_visible_rooms(Vector2(0, 0))

	print("Seed usada: ", seed_value)


# ---------------------------------------------------------
# RNG
# ---------------------------------------------------------

func rand_range(a, b):
	return rng.randi_range(a, b)

func rand_choice(arr):
	return arr[rand_range(0, arr.size() - 1)]

func shuffle_seeded(arr):
	for i in range(arr.size()):
		var j = rng.randi_range(0, arr.size() - 1)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp


# ---------------------------------------------------------
# GENERACIÓN DEL MAPA
# ---------------------------------------------------------

func generate_map():
	map.clear()
	main_path_rooms.clear()

	var start_pos = Vector2(0, 0)
	map[pos_to_key(start_pos)] = create_room(start_pos, "start", init_doors(false))
	main_path_rooms.append(start_pos)

	var target_rooms = rand_range(min_rooms, max_rooms)

	# Camino principal
	for i in range(target_rooms):
		var placed = false
		var attempts = 0

		while not placed and attempts < 100:
			attempts += 1

			var base_pos = rand_choice(main_path_rooms)
			var dirs = ["up", "down", "left", "right"]
			shuffle_seeded(dirs)

			for d in dirs:
				var new_pos = base_pos + dir_to_vector(d)

				if not map.has(pos_to_key(new_pos)):
					map[pos_to_key(new_pos)] = create_room(new_pos, "normal", init_doors(false))
					map[pos_to_key(base_pos)].doors[d] = true
					map[pos_to_key(new_pos)].doors[opposite_dir(d)] = true

					main_path_rooms.append(new_pos)
					placed = true
					break

	# Salas especiales
	place_special_rooms("item", num_item_rooms)
	place_special_rooms("shop", num_shop_rooms)

	# Sala de jefe
	var boss_base = find_far_room(start_pos, 3)
	if boss_base:
		create_branch_room(boss_base, "boss")


func place_special_rooms(type, count):
	for i in range(count):
		var success = false
		for attempt in range(20):
			if create_branch_room(rand_choice(main_path_rooms), type):
				success = true
				break
		if not success:
			print("No se pudo crear sala ", type)


# ---------------------------------------------------------
# CREACIÓN DE SALAS
# ---------------------------------------------------------

func create_branch_room(base_pos, type):
	var free_dir = random_free_direction(base_pos)
	if free_dir == "":
		return false

	var new_pos = base_pos + dir_to_vector(free_dir)
	var doors = init_doors(false)
	doors[opposite_dir(free_dir)] = true

	map[pos_to_key(new_pos)] = create_room(new_pos, type, doors)
	map[pos_to_key(base_pos)].doors[free_dir] = true

	return true


func create_room(pos, type, doors):
	return {
		"pos": pos,
		"type": type,
		"doors": doors
	}


# ---------------------------------------------------------
# CARGA DIFERIDA
# ---------------------------------------------------------

func load_visible_rooms(player_room_pos):
	# Descargar salas lejanas
	for key in room_instances.keys():
		var pos = key_to_pos(key)
		if distance(pos, player_room_pos) > LOAD_RADIUS:
			room_instances[key].queue_free()
			room_instances.erase(key)

	# Cargar salas cercanas
	for key in map.keys():
		var pos = key_to_pos(key)
		if distance(pos, player_room_pos) <= LOAD_RADIUS:
			if not room_instances.has(key):
				instance_room(map[key])


func instance_room(room_data):
	var scene = rand_choice(room_scenes[room_data.type])
	var inst = scene.instantiate()

	inst.position = room_data.pos * ROOM_SIZE
	inst.set_doors(room_data.doors)
	inst.room_position = room_data.pos

	inst.connect("player_entered_room", Callable(self, "_on_player_entered_room"))

	add_child(inst)
	room_instances[pos_to_key(room_data.pos)] = inst

	minimap_data[pos_to_key(room_data.pos)] = room_data.type


func _on_player_entered_room(room_pos):
	load_visible_rooms(room_pos)


# ---------------------------------------------------------
# UTILIDADES
# ---------------------------------------------------------

func pos_to_key(pos): return str(pos.x) + "," + str(pos.y)
func key_to_pos(key):
	var s = key.split(",")
	return Vector2(int(s[0]), int(s[1]))

func init_doors(v): return {"up": v, "down": v, "left": v, "right": v}

func dir_to_vector(d):
	match d:
		"up": return Vector2(0, -1)
		"down": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
	return Vector2()

func opposite_dir(d):
	match d:
		"up": return "down"
		"down": return "up"
		"left": return "right"
		"right": return "left"
	return ""

func random_free_direction(pos):
	var dirs = ["up", "down", "left", "right"]
	shuffle_seeded(dirs)
	for d in dirs:
		var new_pos = pos + dir_to_vector(d)
		if not map.has(pos_to_key(new_pos)):
			return d
	return ""

func find_far_room(from_pos, min_dist):
	var valid = []
	for p in main_path_rooms:
		if distance(p, from_pos) >= min_dist:
			valid.append(p)
	return rand_choice(valid) if valid.size() > 0 else null

func distance(a, b):
	return abs(a.x - b.x) + abs(a.y - b.y)

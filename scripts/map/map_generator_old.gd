extends Node2D

const TILE_SIZE = 32

# Configuración del mapa
var min_rooms = 12
var max_rooms = 24
var num_item_rooms = 2
var num_shop_rooms = 2

# Seed del mapa (puedes cambiarla desde fuera)
@export var seed_value: int

# RNG propio
var rng := RandomNumberGenerator.new()

# Colores para debug visual
var colors = {
	"start": Color.BLUE,
	"normal": Color.GRAY,
	"item": Color.YELLOW,
	"shop": Color.GREEN,
	"boss": Color.RED
}

var map = {}
var main_path_rooms = []

func _ready():
	seed_value = randi()
	rng.seed = seed_value
	generate_map()
	draw_map()
	print("Seed usada: ", seed_value)

# ---------------------------------------------------------
# 🔥 UTILIDADES RNG
# ---------------------------------------------------------

func rand_range(a, b):
	return rng.randi_range(a, b)

func rand_choice(array: Array):
	return array[rand_range(0, array.size() - 1)]
	
func shuffle_seeded(array: Array):
	for i in range(array.size()):
		var j = rng.randi_range(0, array.size() - 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp


# ---------------------------------------------------------
# 🔥 GENERACIÓN DEL MAPA
# ---------------------------------------------------------

func generate_map():
	map.clear()
	main_path_rooms.clear()
	
	var start_pos = Vector2(0, 0)
	map[pos_to_key(start_pos)] = create_room(start_pos, "start", init_doors(false))
	main_path_rooms.append(start_pos)
	
	var target_rooms = rand_range(min_rooms, max_rooms)
	
	for i in range(target_rooms):
		var placed = false
		var attempts = 0
		
		while not placed and attempts < 100:
			attempts += 1
			
			var base_pos = rand_choice(main_path_rooms)
			var directions = ["up", "down", "left", "right"]
			shuffle_seeded(directions)
			
			for d in directions:
				var new_pos = base_pos + dir_to_vector(d)
				
				if not map.has(pos_to_key(new_pos)):
					map[pos_to_key(new_pos)] = create_room(new_pos, "normal", init_doors(false))
					
					map[pos_to_key(base_pos)].doors[d] = true
					map[pos_to_key(new_pos)].doors[opposite_dir(d)] = true
					
					main_path_rooms.append(new_pos)
					placed = true
					break

	# Salas de ítem
	for i in range(num_item_rooms):
		var success = false
		
		if i == 0:
			success = create_branch_room(start_pos, "item")
			if not success:
				for attempt in range(20):
					if create_branch_room(rand_choice(main_path_rooms), "item"):
						success = true
						break
		else:
			for attempt in range(20):
				if create_branch_room(rand_choice(main_path_rooms), "item"):
					success = true
					break
		
		if not success:
			print("❌ ERROR: No se pudo crear sala de ítem #" + str(i+1))

	# Salas de tienda
	for i in range(num_shop_rooms):
		var success = false
		for attempt in range(20):
			if create_branch_room(rand_choice(main_path_rooms), "shop"):
				success = true
				break
		
		if not success:
			print("❌ ERROR: No se pudo crear sala de tienda #" + str(i+1))

	# Sala de jefe
	var boss_base = find_far_room(start_pos, 3)
	var boss_created = false
	
	if boss_base != null:
		boss_created = create_branch_room(boss_base, "boss")
	
	if not boss_created:
		for attempt in range(50):
			var base = rand_choice(main_path_rooms)
			if base != start_pos and create_branch_room(base, "boss"):
				boss_created = true
				break
	
	if not boss_created:
		print("❌ ERROR CRÍTICO: No se pudo crear sala de jefe")

# ---------------------------------------------------------
# 🔥 FUNCIONES AUXILIARES
# ---------------------------------------------------------

func create_branch_room(base_pos, room_type):
	var free_dir = random_free_direction(base_pos)
	
	if free_dir != "":
		var new_pos = base_pos + dir_to_vector(free_dir)
		var doors = init_doors(false)
		doors[opposite_dir(free_dir)] = true
		
		map[pos_to_key(new_pos)] = create_room(new_pos, room_type, doors)
		map[pos_to_key(base_pos)].doors[free_dir] = true
		
		return true
	
	return false

func create_room(pos, type, doors):
	return {"pos": pos, "type": type, "doors": doors}

func init_doors(value):
	return {"up": value, "down": value, "left": value, "right": value}

func pos_to_key(pos):
	return str(pos.x) + "," + str(pos.y)

func dir_to_vector(dir):
	match dir:
		"up": return Vector2(0, -1)
		"down": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
	return Vector2()

func opposite_dir(dir):
	match dir:
		"up": return "down"
		"down": return "up"
		"left": return "right"
		"right": return "left"
	return ""

func random_free_direction(base_pos):
	var dirs = ["up", "down", "left", "right"]
	shuffle_seeded(dirs)
	
	for d in dirs:
		var new_pos = base_pos + dir_to_vector(d)
		if not map.has(pos_to_key(new_pos)):
			return d
	
	return ""

func find_far_room(from_pos, min_distance):
	var valid_rooms = []
	
	for room_pos in main_path_rooms:
		if distance(room_pos, from_pos) >= min_distance:
			valid_rooms.append(room_pos)
	
	if valid_rooms.size() > 0:
		return rand_choice(valid_rooms)
	
	return null

func distance(a, b):
	return abs(a.x - b.x) + abs(a.y - b.y)

# ---------------------------------------------------------
# 🔥 DIBUJO DEL MAPA (DEBUG)
# ---------------------------------------------------------

func draw_map():
	for key in map.keys():
		var room = map[key]
		
		var rect = ColorRect.new()
		rect.color = colors[room.type]
		rect.position = room.pos * TILE_SIZE + Vector2(10, 10)
		rect.size = Vector2(TILE_SIZE - 20, TILE_SIZE - 20)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		
		for dir in ["up", "down", "left", "right"]:
			if room.doors[dir]:
				var door = ColorRect.new()
				door.color = Color.WHITE
				door.mouse_filter = Control.MOUSE_FILTER_IGNORE
				
				match dir:
					"up":
						door.position = room.pos * TILE_SIZE + Vector2(TILE_SIZE/2 - 3, 0)
						door.size = Vector2(6, 10)
					"down":
						door.position = room.pos * TILE_SIZE + Vector2(TILE_SIZE/2 - 3, TILE_SIZE - 10)
						door.size = Vector2(6, 10)
					"left":
						door.position = room.pos * TILE_SIZE + Vector2(0, TILE_SIZE/2 - 3)
						door.size = Vector2(10, 6)
					"right":
						door.position = room.pos * TILE_SIZE + Vector2(TILE_SIZE - 10, TILE_SIZE/2 - 3)
						door.size = Vector2(10, 6)
				
				add_child(door)

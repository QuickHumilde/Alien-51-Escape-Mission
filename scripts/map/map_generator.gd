extends Node2D

const TILE_SIZE = 32  # Aumentado para que las salas sean del tamaño de una pantalla

# Configuración del mapa
var min_rooms = 12
var max_rooms = 24
var num_item_rooms = 2
var num_shop_rooms = 2

# Colores para debug visual
var colors = {
	"start": Color.BLUE,
	"normal": Color.GRAY,
	"item": Color.YELLOW,
	"shop": Color.GREEN,
	"boss": Color.RED
}

var map = {}
var main_path_rooms = []  # Solo salas del camino principal

func _ready():
	generate_map()
	draw_map()

func generate_map():
	map.clear()
	main_path_rooms.clear()
	
	# 1️⃣ Crear sala inicial en 0,0 (centro del mundo)
	var start_pos = Vector2(0, 0)
	map[pos_to_key(start_pos)] = create_room(start_pos, "start", init_doors(false))
	main_path_rooms.append(start_pos)
	
	print("🗺️ Generando mapa con ", max_rooms, " salas máximo...")
	
	# 2️⃣ Generar camino principal con salas normales
	var target_rooms = randi() % (max_rooms - min_rooms + 1) + min_rooms
	
	for i in range(target_rooms):
		var placed = false
		var attempts = 0
		
		while not placed and attempts < 100:
			attempts += 1
			var base_pos = main_path_rooms[randi() % main_path_rooms.size()]
			var directions = ["up", "down", "left", "right"]
			directions.shuffle()
			
			for d in directions:
				var new_pos = base_pos + dir_to_vector(d)
				
				if not map.has(pos_to_key(new_pos)):
					# Crear sala normal
					map[pos_to_key(new_pos)] = create_room(new_pos, "normal", init_doors(false))
					
					# Conectar bidireccionalmente
					map[pos_to_key(base_pos)].doors[d] = true
					map[pos_to_key(new_pos)].doors[opposite_dir(d)] = true
					
					main_path_rooms.append(new_pos)
					placed = true
					break
	
	# 3️⃣ Crear salas de ítem (primera siempre al lado del spawn)
	for i in range(num_item_rooms):
		var success = false
		if i == 0:
			# Primera sala de ítem: SIEMPRE al lado del spawn
			success = create_branch_room(start_pos, "item")
			
			# Si no se pudo crear al lado del spawn, reintentar en otras salas
			if not success:
				for attempt in range(20):
					var base = main_path_rooms[randi() % main_path_rooms.size()]
					if create_branch_room(base, "item"):
						success = true
						break
		else:
			# Resto de salas de ítem: en cualquier sala del camino principal
			for attempt in range(20):
				var base = main_path_rooms[randi() % main_path_rooms.size()]
				if create_branch_room(base, "item"):
					success = true
					break
		
		if not success:
			print("❌ ERROR: No se pudo crear sala de ítem #" + str(i+1))
	
	# 4️⃣ Crear salas de tienda como ramas laterales
	for i in range(num_shop_rooms):
		var success = false
		for attempt in range(20):
			var base = main_path_rooms[randi() % main_path_rooms.size()]
			if create_branch_room(base, "shop"):
				success = true
				break
		
		if not success:
			print("❌ ERROR: No se pudo crear sala de tienda #" + str(i+1))
	
	# 5️⃣ Crear sala de jefe (lejos del spawn) - GARANTIZADO
	var boss_created = false
	var boss_base = find_far_room(start_pos, 3)
	
	if boss_base != null:
		boss_created = create_branch_room(boss_base, "boss")
	
	# Si no se pudo crear lejos, intentar en cualquier sala
	if not boss_created:
		print("⚠️ No se pudo crear jefe lejos, intentando en cualquier sala...")
		for attempt in range(50):
			var base = main_path_rooms[randi() % main_path_rooms.size()]
			if base != start_pos and create_branch_room(base, "boss"):
				boss_created = true
				break
	
	if not boss_created:
		print("❌ ERROR CRÍTICO: No se pudo crear sala de jefe")

func create_branch_room(base_pos, room_type):
	"""Crea una sala especial como rama lateral (callejón sin salida)"""
	var free_dir = random_free_direction(base_pos)
	
	if free_dir != "":
		var new_pos = base_pos + dir_to_vector(free_dir)
		
		# Crear sala con TODAS las puertas en false
		var doors = init_doors(false)
		# Solo activar la puerta que conecta con la sala base
		doors[opposite_dir(free_dir)] = true
		
		map[pos_to_key(new_pos)] = create_room(new_pos, room_type, doors)
		
		# Conectar desde la sala base
		map[pos_to_key(base_pos)].doors[free_dir] = true
		
		return true  # ✅ Éxito
	
	return false  # ❌ No se pudo colocar

func create_room(pos, type, doors):
	return {"pos": pos, "type": type, "doors": doors}

func init_doors(value):
	"""Inicializa todas las puertas con el valor dado"""
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
	"""Encuentra una dirección libre para colocar una sala"""
	var dirs = ["up", "down", "left", "right"]
	dirs.shuffle()
	
	for d in dirs:
		var new_pos = base_pos + dir_to_vector(d)
		if not map.has(pos_to_key(new_pos)):
			return d
	
	return ""

func find_far_room(from_pos, min_distance):
	"""Encuentra una sala del camino principal lejos de una posición"""
	var valid_rooms = []
	
	for room_pos in main_path_rooms:
		if distance(room_pos, from_pos) >= min_distance:
			valid_rooms.append(room_pos)
	
	if valid_rooms.size() > 0:
		return valid_rooms[randi() % valid_rooms.size()]
	
	return null

func distance(a, b):
	return abs(a.x - b.x) + abs(a.y - b.y)

func draw_map():
	
	# Dibujar salas
	for key in map.keys():
		var room = map[key]
		
		# Sala (cuadrado de color)
		var rect = ColorRect.new()
		rect.color = colors[room.type]
		rect.position = room.pos * TILE_SIZE + Vector2(10, 10)
		rect.size = Vector2(TILE_SIZE - 20, TILE_SIZE - 20)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ignorar eventos del mouse
		add_child(rect)
		
		# Dibujar puertas
		for dir in ["up", "down", "left", "right"]:
			if room.doors[dir]:
				var door = ColorRect.new()
				door.color = Color.WHITE
				door.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ignorar eventos del mouse
				
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

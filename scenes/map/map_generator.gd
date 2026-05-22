extends Node2D

# =============================================================================
# VARIABLES Y REFERENCIAS
# =============================================================================

# Tamaño visual de cada celda/sala en el mundo (ancho x alto en píxeles)
@export var room_slot_size: Vector2 = Vector2(640, 384)
# Duración de la transición de cámara al cambiar de sala (en segundos)
@export var transition_duration: float = 0.2

# Nodo que contiene los enemigos de la sala actual (se cachea para no buscarlo cada frame)
var _enemies_container: Node = null
# Flag para no conectar la señal de enemigos más de una vez por sala
var _enemies_connected: bool = false
# Flag para saber si la partida se cargó desde un save (y no es nueva)
var _loaded_from_save: bool = false

# Generador de números aleatorios (controlado por la seed de GameManager)
var rng: RandomNumberGenerator

# Referencias a nodos del árbol de escena
@onready var player: CharacterBody2D = $Player as CharacterBody2D
@onready var cam: Camera2D = $Camera2D as Camera2D
@onready var world: Node2D = $World as Node2D
@onready var minimap: Control = $CanvasLayer/MinimapFrame/Minimap

# Parámetros exportables para la generación del mapa
@export var min_rooms: int = 5
@export var max_rooms: int = 8
@export var num_item_rooms: int = 2
@export var num_shop_rooms: int = 1
@export var boss_min_manhattan_distance_from_start: int = 3

# Configuración de dificultad por piso (índice 0 = piso 1, etc.)
const FLOOR_SETTINGS := [
	{"min_rooms": 6,  "max_rooms": 8,  "item_rooms": 2, "shop_rooms": 1, "boss_dist": 3},
	{"min_rooms": 8,  "max_rooms": 12, "item_rooms": 2, "shop_rooms": 1, "boss_dist": 3},
	{"min_rooms": 12, "max_rooms": 16, "item_rooms": 2, "shop_rooms": 1, "boss_dist": 4},
]

# Diccionario con las escenas de sala agrupadas por tipo
var room_scenes: Dictionary = {
	"start": [ preload("res://scenes/rooms/start/start_room_1.tscn") ],
	"normal": [
		preload("res://scenes/rooms/normal/normal_room_1.tscn"),
		preload("res://scenes/rooms/normal/normal_room_2.tscn"),
		preload("res://scenes/rooms/normal/normal_room_3.tscn"),
		preload("res://scenes/rooms/normal/normal_room_4.tscn"),
		preload("res://scenes/rooms/normal/normal_room_5.tscn"),
		preload("res://scenes/rooms/normal/normal_room_7.tscn"),
		preload("res://scenes/rooms/normal/normal_room_8.tscn"),
		preload("res://scenes/rooms/normal/normal_room_9.tscn"),
		preload("res://scenes/rooms/normal/normal_room_10.tscn"),
		preload("res://scenes/rooms/normal/normal_room_11.tscn"),
		preload("res://scenes/rooms/normal/normal_room_12.tscn"),
		preload("res://scenes/rooms/normal/normal_room_13.tscn"),
		preload("res://scenes/rooms/normal/normal_room_14.tscn"),
		preload("res://scenes/rooms/normal/normal_room_15.tscn"),
		preload("res://scenes/rooms/normal/normal_room_16.tscn"),
		preload("res://scenes/rooms/normal/normal_room_17.tscn"),
		preload("res://scenes/rooms/normal/normal_room_18.tscn"),
		preload("res://scenes/rooms/normal/normal_room_19.tscn"),
		preload("res://scenes/rooms/normal/normal_room_20.tscn"),
		preload("res://scenes/rooms/normal/normal_room_21.tscn"),
		preload("res://scenes/rooms/normal/normal_room_22.tscn"),
		preload("res://scenes/rooms/normal/normal_room_23.tscn"),
		preload("res://scenes/rooms/normal/normal_room_24.tscn"),
		preload("res://scenes/rooms/normal/normal_room_25.tscn"),
		preload("res://scenes/rooms/normal/normal_room_26.tscn"),
		preload("res://scenes/rooms/normal/normal_room_27.tscn"),
	],
	"item": [ preload("res://scenes/rooms/item/item_room_1.tscn") ],
	"shop": [
		preload("res://scenes/rooms/shop/shop_room_1.tscn"),
		preload("res://scenes/rooms/shop/shop_room_2.tscn"),
	],
}

# Escenas de sala de boss agrupadas por ID de jefe
const BOSSES: Dictionary = {
	"cyborg_unicorn": [
		preload("res://scenes/rooms/boss/boss_room_cyborg_unicorn_1.tscn"),
		preload("res://scenes/rooms/boss/boss_room_cyborg_unicorn_2.tscn"),
	],
	"long_arms": [
		preload("res://scenes/rooms/boss/boss_room_long_arms_1.tscn"),
		preload("res://scenes/rooms/boss/boss_room_long_arms_2.tscn"),
	],
	"buffed_alien": [
		preload("res://scenes/rooms/boss/boss_room_buffed_alien_1.tscn"),
	],
}

# Estado del mapa en tiempo de ejecución
var map: Dictionary = {}                    # Datos de cada sala, indexados por "x,y"
var main_path_rooms: Array[Vector2] = []    # Posiciones que forman el camino principal
var room_instances: Dictionary = {}         # Nodos instanciados de sala, indexados por "x,y"
var current_room_pos: Vector2 = Vector2.ZERO
var current_room: Node2D = null
var transitioning: bool = false             # Evita transiciones simultáneas

# Caché de capacidades de puertas por ruta de escena (evita instanciar repetidamente)
var _door_caps_cache: Dictionary = {}


# =============================================================================
# INICIALIZACIÓN (_ready)
# =============================================================================

func _ready() -> void:
	# Reinicia el flag de muerte del jugador al arrancar el nivel
	Signals.player_is_dead = false
	_loaded_from_save = false

	# Si el jugador pidió continuar y hay save, lo carga; si no, genera una partida nueva
	if GameManager.continue_requested and SaveManager.has_save():
		_loaded_from_save = SaveManager.load_run(self, player as Character, minimap)
		GameManager.continue_requested = false

	if not _loaded_from_save:
		GameManager.generate_seed()
		rng = GameManager.rng
		_apply_floor_settings()
		generate_map()
		_print_map_type_counts()
		current_room_pos = Vector2.ZERO
	else:
		rng = GameManager.rng
		_apply_floor_settings()

	# Spawnea la sala inicial y coloca la cámara en ella
	current_room = await _spawn_room_at(current_room_pos)
	_snap_camera_to_room(current_room)

	if not _loaded_from_save:
		_place_player(current_room, "")

	# Actualiza el minimapa con los datos del mapa generado
	if minimap != null and minimap.has_method("set_data"):
		minimap.call("set_data", map, current_room_pos, GameManager.get_current_floor())

	print("Seed usada: ", GameManager.seed_value)

	_watch_room_cleared(current_room)

	if not _loaded_from_save:
		AudioManager.play_floor_music()

	_emit_room_changed()

	# Guarda la partida nada más entrar al primer cuarto
	if not _loaded_from_save:
		var key := pos_to_key(current_room_pos)
		var rt := "normal"
		if map.has(key):
			rt = str((map[key] as Dictionary).get("type", "normal"))
		_save_run_now(rt)


# =============================================================================
# CAMBIO DE PISO
# =============================================================================

# Avanza al siguiente piso: limpia el mundo actual, regenera el mapa y reinicia al jugador.
func next_floor() -> void:
	if transitioning:
		return
	transitioning = true

	# Guarda el estado del cuarto actual antes de destruirlo
	_store_current_room_runtime_state()

	GameManager.next_floor()

	# Elimina todas las salas instanciadas del mundo
	for child in world.get_children():
		child.queue_free()

	room_instances.clear()
	_apply_floor_settings()
	generate_map()
	_print_map_type_counts()

	# Spawnea la sala de inicio del nuevo piso y coloca jugador/cámara
	current_room_pos = Vector2.ZERO
	current_room = await _spawn_room_at(current_room_pos)
	_snap_camera_to_room(current_room)
	_place_player(current_room, "")

	if minimap != null and minimap.has_method("set_data"):
		minimap.call("set_data", map, current_room_pos, GameManager.get_current_floor())

	_watch_room_cleared(current_room)

	Signals.floor_changed.emit()

	AudioManager.play_floor_music()
	_emit_room_changed()

	var key := pos_to_key(current_room_pos)
	var rt := "normal"
	if map.has(key):
		rt = str((map[key] as Dictionary).get("type", "normal"))
	_save_run_now(rt)

	transitioning = false


# =============================================================================
# SEÑALES DE CAMBIO DE SALA
# =============================================================================

# Emite la señal room_changed con el tipo de la sala actual y guarda el estado en curso.
func _emit_room_changed() -> void:
	var key := pos_to_key(current_room_pos)
	if not map.has(key):
		return
	var data := map[key] as Dictionary
	var room_type := str(data.get("type", "normal"))
	Signals.room_changed.emit(room_type)

	_store_current_room_runtime_state()


# =============================================================================
# PERSISTENCIA DEL ESTADO DE SALA EN TIEMPO DE EJECUCIÓN
# =============================================================================

# Captura y almacena en el mapa el estado actual de todos los spawners de la sala activa.
func _store_current_room_runtime_state() -> void:
	if current_room == null:
		return
	var key := pos_to_key(current_room_pos)
	if not map.has(key):
		return
	var d := map[key] as Dictionary
	d["spawners"] = _capture_room_spawner_state(current_room)

# Recorre los spawners de una sala y devuelve un diccionario con su estado serializado.
func _capture_room_spawner_state(room: Node) -> Dictionary:
	var out: Dictionary = {}
	if room == null:
		return out

	# Lista de clases de spawner que deben persistir su estado
	var spawner_classes := [
		"ItemSpawner",
		"RewardSpawner",
		"ProductSpawner",
		"RoomClearItemSpawner",
		"Staircase",
	]

	for cls in spawner_classes:
		for sp in room.find_children("", cls, true, false):
			if sp == null:
				continue
			if sp.has_method("get_spawner_key") and sp.has_method("get_save_state"):
				out[sp.get_spawner_key()] = sp.get_save_state()

	return out

# Aplica un estado previamente guardado a los spawners de una sala recién instanciada.
func _apply_room_spawner_state(room: Node, spawners_state: Dictionary) -> void:
	if room == null:
		return
	if spawners_state == null:
		return

	var spawner_classes := [
		"ItemSpawner",
		"RewardSpawner",
		"ProductSpawner",
		"RoomClearItemSpawner",
		"Staircase",
	]

	for cls in spawner_classes:
		for sp in room.find_children("", cls, true, false):
			if sp == null:
				continue
			if not (sp.has_method("get_spawner_key") and sp.has_method("load_save_state")):
				continue
			var k = sp.get_spawner_key()
			if spawners_state.has(k):
				sp.load_save_state(spawners_state[k] as Dictionary)


# =============================================================================
# CONFIGURACIÓN DE PISO
# =============================================================================

# Aplica los parámetros de generación correspondientes al piso actual (salas, distancia de boss…).
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

# Imprime por consola cuántas salas de cada tipo se generaron (útil para debug).
func _print_map_type_counts() -> void:
	var counts: Dictionary = {"start": 0, "normal": 0, "item": 0, "shop": 0, "boss": 0}
	for k in map.keys():
		var t := str((map[k] as Dictionary).get("type", "normal"))
		if not counts.has(t):
			counts[t] = 0
		counts[t] += 1


# =============================================================================
# SPAWN Y TRANSICIÓN DE SALAS
# =============================================================================

# Devuelve la instancia de sala en room_pos: la reutiliza si ya existe, o la crea si no.
func _spawn_room_at(room_pos: Vector2) -> Node2D:
	var key: String = pos_to_key(room_pos)
	if room_instances.has(key) and is_instance_valid(room_instances[key]):
		# La sala ya estaba instanciada: solo la hace visible y activa
		var existing: Node2D = room_instances[key] as Node2D
		existing.visible = true
		existing.process_mode = Node.PROCESS_MODE_INHERIT
		return existing

	# Instancia la sala desde su escena, la posiciona en el mundo y conecta señales
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

	# Restaura el estado de los spawners si viene de un save
	var sp_state: Dictionary = data.get("spawners", {}) as Dictionary
	_apply_room_spawner_state(room, sp_state)

	return room

# Instancia la escena correcta para una sala según sus datos (prioriza scene_path guardado).
func _instantiate_room_for(data: Dictionary) -> Node2D:
	if data.has("scene_path"):
		var p: String = str(data["scene_path"])
		var ps: PackedScene = load(p) as PackedScene
		if ps != null:
			return ps.instantiate() as Node2D

	# Si no hay scene_path fija, elige una escena aleatoria del tipo correspondiente
	var room_type: String = str(data.get("type", "normal"))
	var list_any: Variant = room_scenes.get(room_type, room_scenes["normal"])
	var list: Array = list_any as Array
	var scene_any: Variant = list[rng.randi_range(0, list.size() - 1)]
	var scene: PackedScene = scene_any as PackedScene
	return scene.instantiate() as Node2D

# Callback disparado cuando el jugador toca una puerta; valida y lanza la transición.
func _on_door_entered(dir: String) -> void:
	if transitioning:
		return

	var d: String = dir.strip_edges().to_lower()
	var step := dir_to_vector(d)
	var next_pos: Vector2 = current_room_pos + step
	# Solo transiciona si la sala vecina existe en el mapa
	if not map.has(pos_to_key(next_pos)):
		return

	transitioning = true
	call_deferred("_start_transition_deferred", next_pos, d)

# Lanzador diferido para evitar problemas de frame al iniciar la transición.
func _start_transition_deferred(next_pos: Vector2, exit_dir: String) -> void:
	await _transition_to(next_pos, exit_dir)

# Gestiona la transición completa entre dos salas: oculta la anterior, hace aparecer la nueva,
# recoloca al jugador y desliza la cámara.
func _transition_to(next_pos: Vector2, exit_dir: String) -> void:
	_store_current_room_runtime_state()

	var prev_room: Node2D = current_room
	var next_room: Node2D = await _spawn_room_at(next_pos)

	# Desactiva la sala anterior para no gastar recursos
	if is_instance_valid(prev_room):
		prev_room.visible = false
		prev_room.process_mode = Node.PROCESS_MODE_DISABLED

	next_room.visible = true
	next_room.process_mode = Node.PROCESS_MODE_INHERIT

	_place_player(next_room, opposite_dir(exit_dir))
	await get_tree().process_frame

	# Desliza la cámara del centro de la sala anterior al centro de la nueva
	var from_cam: Vector2 = _room_center_node(prev_room)
	var to_cam: Vector2 = _room_center_node(next_room)
	await _slide_camera(from_cam, to_cam, transition_duration)

	current_room = next_room
	current_room_pos = next_pos
	_enemies_connected = false
	_enemies_container = null

	if minimap != null and minimap.has_method("set_data"):
		minimap.call("set_data", map, current_room_pos, GameManager.get_current_floor())

	transitioning = false

	_emit_room_changed()
	_watch_room_cleared(current_room)


# =============================================================================
# COLOCACIÓN DEL JUGADOR Y CÁMARA
# =============================================================================

# Coloca al jugador en el punto de spawn de la sala según la dirección de entrada.
func _place_player(room: Node2D, entered_from_dir: String) -> void:
	if room.has_method("get_spawn_global"):
		player.global_position = room.call("get_spawn_global", entered_from_dir) as Vector2
	else:
		player.global_position = room.global_position

# Teleporta la cámara instantáneamente al centro de la sala dada.
func _snap_camera_to_room(room: Node2D) -> void:
	cam.global_position = _room_center_node(room)

# Devuelve la posición global del centro de una sala (usa get_center_global si está disponible).
func _room_center_node(room: Node2D) -> Vector2:
	if room != null and room.has_method("get_center_global"):
		return room.call("get_center_global") as Vector2
	return room.global_position

# Anima el deslizamiento de la cámara entre dos puntos usando interpolación suavizada (smoothstep).
func _slide_camera(from_pos: Vector2, to_pos: Vector2, duration: float) -> void:
	var t: float = 0.0
	while t < duration:
		t += get_process_delta_time()
		var a: float = clamp(t / duration, 0.0, 1.0)
		a = a * a * (3.0 - 2.0 * a)  # Smoothstep
		cam.global_position = from_pos.lerp(to_pos, a)
		await get_tree().process_frame
	cam.global_position = to_pos


# =============================================================================
# UTILIDADES DE ALEATORIEDAD
# =============================================================================

# Entero aleatorio en el rango [a, b] usando la seed controlada.
func rand_range(a: int, b: int) -> int: return rng.randi_range(a, b)

# Elemento aleatorio de un array usando la seed controlada.
func rand_choice(array: Array) -> Variant: return array[rand_range(0, array.size() - 1)]

# Mezcla un array in-place con el algoritmo de Fisher-Yates usando la seed controlada.
func shuffle_seeded(array: Array) -> void:
	for i in range(array.size()):
		var j: int = rng.randi_range(0, array.size() - 1)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp


# =============================================================================
# UTILIDADES DEL MAPA
# =============================================================================

# Crea y devuelve un diccionario con los datos base de una sala nueva.
func create_room(pos: Vector2, type: String, doors: Dictionary, scene_path: String) -> Dictionary:
	return {
		"pos": pos,
		"type": type,
		"doors": doors,
		"scene_path": scene_path,
		"cleared": false,
		"had_enemies": false
	}

# Devuelve la clave string de la sala en la posición actual del jugador.
func _room_key() -> String:
	return pos_to_key(current_room_pos)

# Devuelve los datos del mapa de la sala actual.
func _room_data() -> Dictionary:
	var key := _room_key()
	if not map.has(key):
		return {}
	return map[key] as Dictionary

# Establece un flag booleano en los datos de la sala actual.
func _set_room_flag(flag: String, value: bool) -> void:
	var key := _room_key()
	if not map.has(key):
		return
	(map[key] as Dictionary)[flag] = value

# Inicializa un diccionario de puertas con todas las direcciones en el mismo valor.
func init_doors(value: bool) -> Dictionary:
	return {"up": value, "down": value, "left": value, "right": value}

# Convierte una posición Vector2 a clave string "x,y".
func pos_to_key(pos: Vector2) -> String:
	return str(pos.x) + "," + str(pos.y)

# Convierte una dirección string a su Vector2 correspondiente.
func dir_to_vector(dir: String) -> Vector2:
	match dir:
		"up": return Vector2(0, -1)
		"down": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
		_: return Vector2.ZERO

# Devuelve la dirección contraria a la indicada.
func opposite_dir(dir: String) -> String:
	match dir:
		"up": return "down"
		"down": return "up"
		"left": return "right"
		"right": return "left"
	return ""

# Devuelve los datos de mapa de una posición concreta (o diccionario vacío si no existe).
func _get_room_data_at(pos: Vector2) -> Dictionary:
	var key := pos_to_key(pos)
	if not map.has(key):
		return {}
	return map[key] as Dictionary

# Comprueba si una sala en pos está marcada como despejada.
func _is_room_cleared(pos: Vector2) -> bool:
	var data := _get_room_data_at(pos)
	return bool(data.get("cleared", false))

# Marca o desmarca como despejada la sala en pos.
func _set_room_cleared(pos: Vector2, value: bool) -> void:
	var key := pos_to_key(pos)
	if not map.has(key):
		return
	(map[key] as Dictionary)["cleared"] = value

# Calcula la distancia Manhattan entre dos celdas del grid.
func manhattan(a: Vector2, b: Vector2) -> int:
	return int(abs(a.x - b.x) + abs(a.y - b.y))


# =============================================================================
# CAPACIDADES DE PUERTAS (DOOR CAPS)
# =============================================================================

# Obtiene qué puertas soporta una escena instanciándola una vez y cacheando el resultado.
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

# Versión de get_scene_door_caps que acepta la ruta de escena directamente como string.
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

# Comprueba si una sala base permite una salida en la dirección indicada según sus door caps.
func _room_allows_exit(base_data: Dictionary, dir: String) -> bool:
	if not base_data.has("scene_path"):
		return true
	var p := str(base_data.get("scene_path", ""))
	if p.is_empty():
		return true
	var caps := _get_caps_from_scene_path(p)
	return bool(caps.get(dir, true))

# Elige una escena de sala del tipo indicado que tenga puerta en required_entry_dir.
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


# =============================================================================
# SELECCIÓN DE BOSS
# =============================================================================

# Elige el ID del boss para el piso actual evitando repetir bosses ya usados.
func _pick_boss_id_for_floor() -> String:
	# En el último piso siempre usa el boss final
	if GameManager.has_method("is_last_floor") and GameManager.is_last_floor():
		return str(GameManager.get("final_boss_id"))

	var final_id := str(GameManager.get("final_boss_id"))
	var available: Array[String] = []

	# Filtra bosses ya usados y el boss final (reservado para el último piso)
	for boss_id_any in BOSSES.keys():
		var boss_id := str(boss_id_any)
		if boss_id == final_id and final_id != "":
			continue
		if GameManager.has_method("is_boss_used") and GameManager.is_boss_used(boss_id):
			continue
		available.append(boss_id)

	# Si no quedan disponibles, permite repetir (excluye solo el boss final)
	if available.is_empty():
		for boss_id_any in BOSSES.keys():
			var boss_id := str(boss_id_any)
			if boss_id == final_id and final_id != "":
				continue
			available.append(boss_id)

	shuffle_seeded(available)
	return available[0]

# Elige la escena de sala de boss para un boss_id concreto que tenga la puerta de entrada requerida.
func _pick_boss_room_scene(boss_id: String, required_entry_dir: String) -> PackedScene:
	var list: Array = BOSSES.get(boss_id, [])
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


# =============================================================================
# GENERACIÓN DEL MAPA
# =============================================================================

# Comprueba si ya existe al menos una sala del tipo indicado en el mapa actual.
func _has_room_type(t: String) -> bool:
	for k in map.keys():
		var data := map[k] as Dictionary
		if str(data.get("type", "")) == t:
			return true
	return false

# Punto de entrada de la generación: reintenta hasta 30 veces hasta que exista sala de boss.
func generate_map() -> void:
	var tries := 0
	while true:
		tries += 1
		map.clear()
		main_path_rooms.clear()
		room_instances.clear()

		# 1. Sala inicial en el origen
		var start_pos := Vector2.ZERO
		var start_scene: PackedScene = room_scenes["start"][0]
		map[pos_to_key(start_pos)] = create_room(start_pos, "start", init_doors(false), start_scene.resource_path)
		main_path_rooms.append(start_pos)

		# 2. Sala de item adyacente al inicio
		_create_start_item_branch(start_pos)
		# 3. Salas normales que forman el camino principal
		var target_normals: int = rand_range(min_rooms, max_rooms)
		_create_main_normals(start_pos, target_normals)
		# 4. Salas de item adicionales como ramales ciegos
		_create_extra_item_branches(start_pos, num_item_rooms - 1)
		# 5. Salas de tienda como ramales ciegos
		_create_shop_branches(num_shop_rooms)
		# 6. Sala de boss como ramal ciego lejano del inicio
		_create_boss_branch(start_pos)
		# 7. Elimina puertas que apunten a salas inexistentes
		_cleanup_doors_against_missing_neighbors()

		if _has_room_type("boss"):
			break
		if tries >= 30:
			push_error("No se pudo generar una sala de boss tras " + str(tries) + " intentos.")
			break

# Crea una sala de item directamente adyacente a la sala inicial.
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
		return  # Solo crea una sala de item aquí

# Genera las salas normales del camino principal expandiendo aleatoriamente desde las ya existentes.
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

# Crea las salas de item extra (las que van más allá de la primera) como ramales sin salida.
func _create_extra_item_branches(_start_pos: Vector2, count: int) -> void:
	for i in range(max(0, count)):
		if not _create_dead_end_branch("item", Vector2.ZERO, 25):
			print("No se pudieron crear todas las salas de item")

# Crea las salas de tienda como ramales sin salida.
func _create_shop_branches(count: int) -> void:
	for i in range(max(0, count)):
		if not _create_dead_end_branch("shop", Vector2.ZERO, 25):
			print("No se pudieron crear todas las tiendas")

# Crea la sala de boss como ramal sin salida desde una sala lo suficientemente lejos del inicio.
func _create_boss_branch(start_pos: Vector2) -> void:
	# Solo considera salas del camino principal que estén a distancia mínima del inicio
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

# Intenta colocar una sala especial como ramal ciego adyacente a una sala existente.
# Devuelve true si lo consigue, false si agota los intentos.
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

			var special_scene: PackedScene = null

			if room_type == "boss":
				var boss_id := _pick_boss_id_for_floor()
				special_scene = _pick_boss_room_scene(boss_id, opposite_dir(d))
				if special_scene == null:
					continue
				if GameManager.has_method("mark_boss_used"):
					GameManager.mark_boss_used(boss_id)
			else:
				special_scene = pick_scene_with_required_door(room_type, opposite_dir(d))
				if special_scene == null:
					continue

			var doors := init_doors(false)
			doors[opposite_dir(d)] = true
			map[pos_to_key(new_pos)] = create_room(new_pos, room_type, doors, special_scene.resource_path)
			(base_data["doors"] as Dictionary)[d] = true
			return true
	return false

# Recorre todas las salas y cierra las puertas que apuntan a celdas vacías del mapa.
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


# =============================================================================
# DETECCIÓN DE SALA DESPEJADA (TODOS LOS ENEMIGOS MUERTOS)
# =============================================================================

# Conecta la señal del nodo Enemies para detectar cuándo se vacía la sala.
# Solo actúa si la sala no estaba ya despejada y tiene enemigos.
func _watch_room_cleared(room: Node) -> void:
	var key := pos_to_key(current_room_pos)
	if not map.has(key):
		return
	var data := map[key] as Dictionary
	if bool(data.get("cleared", false)):
		return

	var enemies := room.get_node_or_null("Enemies")
	if enemies == null:
		return

	# Si ya no hay enemigos en el nodo, no hay nada que vigilar
	if _is_enemies_empty(enemies):
		return

	data["had_enemies"] = true

	_enemies_container = enemies
	if not _enemies_connected:
		enemies.child_exiting_tree.connect(_on_enemies_child_exiting_tree)
		_enemies_connected = true

	_check_room_cleared()

# Callback llamado cuando un hijo sale del árbol del nodo Enemies (ej: enemigo muerto/eliminado).
func _on_enemies_child_exiting_tree(_child: Node) -> void:
	# Espera un frame para que el nodo termine de salir antes de comprobar
	await get_tree().process_frame
	_check_room_cleared()

# Callback alternativo para cuando un hijo ha salido completamente del árbol.
func _on_enemies_child_exited(_child: Node) -> void:
	_check_room_cleared()

# Comprueba si todos los enemigos han muerto y, de ser así, marca la sala como despejada.
func _check_room_cleared() -> void:
	if current_room == null:
		return

	var key := pos_to_key(current_room_pos)
	if not map.has(key):
		return
	var data := map[key] as Dictionary

	if bool(data.get("cleared", false)):
		return
	if not bool(data.get("had_enemies", false)):
		return

	var enemies := current_room.get_node_or_null("Enemies")
	if enemies == null:
		return

	if _is_enemies_empty(enemies):
		data["cleared"] = true
		Signals.room_cleared.emit()

# Devuelve true si no hay ningún nodo en el grupo "enemy" dentro del nodo enemies.
func _is_enemies_empty(enemies: Node) -> bool:
	for e in enemies.get_children():
		if e.is_in_group("enemy"):
			return false
	return true

# Versión legacy: detecta la salida de un enemigo desde fuera de la sala (room distinto al actual).
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

# Emite room_cleared si el nodo enemies está vacío (helper para uso interno).
func _emit_room_cleared_if_empty(enemies: Node) -> void:
	for e in enemies.get_children():
		if e.is_in_group("enemy"):
			return
	Signals.room_cleared.emit()


# =============================================================================
# GUARDADO
# =============================================================================

# Guarda el estado actual de la partida a través del SaveManager.
func _save_run_now(room_type: String = "") -> void:
	if SaveManager != null:
		SaveManager.save_run(self, player as Character, minimap, room_type)

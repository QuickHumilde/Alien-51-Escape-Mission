extends Control

# =============================================================================
# VARIABLES Y CONFIGURACIÓN VISUAL
# =============================================================================

# Tamaño en píxeles de cada celda del minimapa
@export var cell_size: float = 10.0
# Margen interior alrededor del contenido del minimapa
@export var padding: float = 12.0
# Margen adicional para el rectángulo de la sala actual (lo hace ligeramente más pequeño)
@export var current_inset: float = 2.0

# Colores de relleno de cada tipo de sala
@export var color_normal: Color = Color(0.749, 0.749, 0.749, 1.0)
@export var color_start: Color = Color(0.4, 0.9, 0.4, 0.95)
@export var color_item: Color = Color(0.3, 0.6, 1.0, 0.95)
@export var color_shop: Color = Color(1.0, 0.8, 0.2, 0.95)
@export var color_boss: Color = Color(1.0, 0.3, 0.3, 0.95)
# Color del borde/indicador de la sala en la que está el jugador actualmente
@export var color_current: Color = Color(1.0, 1.0, 1.0, 1.0)

# Color y grosor del borde de salas que aún no han sido visitadas
@export var color_border_unvisited: Color = Color(1.0, 0.2, 0.2, 0.95)
@export var border_width_unvisited: float = 1.0

# Color y grosor de los pasillos/líneas que conectan salas
@export var corridor_color: Color = Color(1.0, 1.0, 1.0, 0.949)
@export var corridor_width: float = 2.0

# Proporción de la celda que ocupa el stub (segmento de pasillo que sale de la sala)
@export var stub_len_ratio: float = 0.45
# Desplazamiento del inicio del stub desde el centro de la sala
@export var stub_inset: float = 1.0

# Datos del mapa del dungeon (misma estructura que en el nivel principal)
var dungeon_map: Dictionary = {}
# Posición en el grid de la sala donde está el jugador
var current_pos: Vector2 = Vector2.ZERO

# Registro de salas visitadas, indexadas por clave "x,y"
var visited: Dictionary = {}

# Mínimos del grid para calcular el offset de dibujo
var _min_x: float = 0.0
var _min_y: float = 0.0
# Punto de origen en pantalla a partir del que se dibuja el minimapa
var _origin: Vector2 = Vector2.ZERO

# Tamaño total del control del minimapa
@export var minimap_size: Vector2 = Vector2(220, 180)

# ID del último piso mostrado; si cambia, se limpian las salas visitadas
var _last_floor_id: int = -1


# =============================================================================
# INICIALIZACIÓN Y EVENTOS
# =============================================================================

func _ready() -> void:
	# Oculta el minimapa cuando el jugador muere
	Signals.show_death_menu.connect(_on_death)

func _on_death():
	self.hide()


# =============================================================================
# ACTUALIZACIÓN DE DATOS
# =============================================================================

# Recibe el mapa actualizado, la posición actual y el ID de piso.
# Si el piso cambió, resetea las salas visitadas antes de aplicar los nuevos datos.
func set_data(m: Dictionary, cur: Vector2, floor_id: int) -> void:
	if floor_id != _last_floor_id:
		visited.clear()
		_last_floor_id = floor_id

	dungeon_map = m
	current_pos = cur

	mark_visited(current_pos)
	queue_redraw()

# Marca una posición del grid como visitada.
func mark_visited(pos: Vector2) -> void:
	visited[_pos_key(pos)] = true

# Convierte una posición Vector2 a clave string "x,y".
func _pos_key(pos: Vector2) -> String:
	return str(pos.x) + "," + str(pos.y)


# =============================================================================
# CÁLCULO DE SALAS VISIBLES
# =============================================================================

# Construye el conjunto de claves de salas que deben dibujarse:
# todas las visitadas más las salas adyacentes a ellas (las que el jugador puede ver desde una puerta).
func _build_visible_keys() -> Dictionary:
	var visible: Dictionary = {}

	# Si todavía no se ha visitado nada, muestra solo la sala actual
	if visited.is_empty():
		visible[_pos_key(current_pos)] = true
		return visible

	for k in visited.keys():
		visible[k] = true

		# Añade las salas vecinas accesibles mediante puertas abiertas
		var d: Dictionary = dungeon_map.get(k, {})
		var rp: Vector2 = d.get("pos", Vector2.ZERO)
		var doors: Dictionary = d.get("doors", {})

		if doors.get("up", false):
			var nk := _pos_key(rp + Vector2(0, -1))
			if dungeon_map.has(nk):
				visible[nk] = true

		if doors.get("down", false):
			var nk := _pos_key(rp + Vector2(0, 1))
			if dungeon_map.has(nk):
				visible[nk] = true

		if doors.get("left", false):
			var nk := _pos_key(rp + Vector2(-1, 0))
			if dungeon_map.has(nk):
				visible[nk] = true

		if doors.get("right", false):
			var nk := _pos_key(rp + Vector2(1, 0))
			if dungeon_map.has(nk):
				visible[nk] = true

	return visible


# =============================================================================
# CONVERSIÓN DE COORDENADAS GRID → PANTALLA
# =============================================================================

# Devuelve la esquina superior izquierda en pantalla de una celda del grid.
func _room_top_left(room_pos: Vector2) -> Vector2:
	return _origin + Vector2((room_pos.x - _min_x) * cell_size, (room_pos.y - _min_y) * cell_size)

# Devuelve el centro en pantalla de una celda del grid.
func _room_center(room_pos: Vector2) -> Vector2:
	return _room_top_left(room_pos) + Vector2(cell_size * 0.5, cell_size * 0.5)

# Devuelve el color de relleno correspondiente al tipo de sala.
func _room_color(t: String) -> Color:
	match t:
		"start": return color_start
		"item": return color_item
		"shop": return color_shop
		"boss": return color_boss
		_: return color_normal


# =============================================================================
# DIBUJO DEL MINIMAPA (_draw)
# =============================================================================

# Punto de entrada del renderizado: calcula límites del grid, dibuja pasillos y luego salas.
func _draw() -> void:
	if dungeon_map.is_empty():
		return

	var visible_keys := _build_visible_keys()
	if visible_keys.is_empty():
		return

	# Calcula los límites del grid para centrar el contenido dentro del padding
	var min_x := 999999.0
	var max_x := -999999.0
	var min_y := 999999.0
	var max_y := -999999.0

	for key in visible_keys.keys():
		var d: Dictionary = dungeon_map.get(key, {})
		var rp: Vector2 = d.get("pos", Vector2.ZERO)
		min_x = min(min_x, rp.x)
		max_x = max(max_x, rp.x)
		min_y = min(min_y, rp.y)
		max_y = max(max_y, rp.y)

	_min_x = min_x
	_min_y = min_y

	_origin = Vector2(padding, padding)

	# Primera pasada: dibuja stubs y líneas de corredor (quedan detrás de los rectángulos de sala)
	for key in visible_keys.keys():
		var d: Dictionary = dungeon_map.get(key, {})
		var rp: Vector2 = d.get("pos", Vector2.ZERO)
		var doors: Dictionary = d.get("doors", {})
		var c := _room_center(rp)

		# Dibuja los stubs (segmentos cortos) en cada dirección con puerta
		_draw_stub(c, doors, "up")
		_draw_stub(c, doors, "down")
		_draw_stub(c, doors, "left")
		_draw_stub(c, doors, "right")

		# Dibuja la línea completa de corredor hacia la derecha si la sala vecina es visible
		var right_key := _pos_key(rp + Vector2(1, 0))
		if doors.get("right", false) and visible_keys.has(right_key):
			var c2 := _room_center(rp + Vector2(1, 0))
			draw_line(c, c2, corridor_color, corridor_width)

		# Dibuja la línea completa de corredor hacia abajo si la sala vecina es visible
		var down_key := _pos_key(rp + Vector2(0, 1))
		if doors.get("down", false) and visible_keys.has(down_key):
			var c3 := _room_center(rp + Vector2(0, 1))
			draw_line(c, c3, corridor_color, corridor_width)

	# Segunda pasada: dibuja los rectángulos de sala encima de los pasillos
	for key in visible_keys.keys():
		var d: Dictionary = dungeon_map.get(key, {})
		var rp: Vector2 = d.get("pos", Vector2.ZERO)
		var t: String = str(d.get("type", "normal"))

		var pos2 := _room_top_left(rp)
		var rect := Rect2(pos2 + Vector2(1, 1), Vector2(cell_size - 3, cell_size - 3))

		# Relleno con el color del tipo de sala
		draw_rect(rect, _room_color(t), true)

		# Borde: negro semitransparente si visitada, rojo si no visitada
		var is_visited := visited.has(key)
		var border_color := Color(0, 0, 0, 0.6) if is_visited else color_border_unvisited
		var border_w := 1.0 if is_visited else border_width_unvisited
		draw_rect(rect, border_color, false, border_w)

	# Tercera pasada: dibuja el indicador de sala actual encima de todo
	var cur_key := _pos_key(current_pos)
	if visible_keys.has(cur_key):
		var cur_top_left := _room_top_left(current_pos) + Vector2(current_inset, current_inset)
		var cur_size := Vector2(cell_size, cell_size) - Vector2(current_inset * 2.0, current_inset * 2.0)
		var cur_rect := Rect2(cur_top_left, cur_size)

		# Sombra exterior para que el indicador resalte sobre cualquier fondo
		var shadow_grow := 0.5
		draw_rect(cur_rect.grow(shadow_grow), Color(0, 0, 0, 0.75), false, 2.0)
		draw_rect(cur_rect, color_current, false, 1.0)


# =============================================================================
# DIBUJO DE STUBS (SEGMENTOS DE PASILLO)
# =============================================================================

# Dibuja un segmento corto que sale del centro de la sala en la dirección indicada,
# siempre que esa puerta esté abierta. Se usa para salas cuya vecina no es visible aún.
func _draw_stub(center: Vector2, doors: Dictionary, dir: String) -> void:
	if not doors.get(dir, false):
		return

	var stub_len := cell_size * stub_len_ratio
	var from := center
	var to := center

	match dir:
		"up":
			from = center + Vector2(0, -stub_inset)
			to = center + Vector2(0, -stub_len)
		"down":
			from = center + Vector2(0, stub_inset)
			to = center + Vector2(0, stub_len)
		"left":
			from = center + Vector2(-stub_inset, 0)
			to = center + Vector2(-stub_len, 0)
		"right":
			from = center + Vector2(stub_inset, 0)
			to = center + Vector2(stub_len, 0)

	draw_line(from, to, corridor_color, corridor_width)

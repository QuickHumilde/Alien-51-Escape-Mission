extends Node2D

signal door_entered(dir: String)

# =============================================================================
# VARIABLES Y CONFIGURACIÓN EXPORTADA
# =============================================================================

# Qué puertas soporta físicamente esta sala (se consulta al generar el mapa)
@export var door_caps := { "up": true, "down": true, "left": true, "right": true }
# Si es true, las puertas permanecen cerradas hasta eliminar todos los enemigos
@export var lock_doors_until_clear: bool = true
# Ruta al nodo que contiene los hijos de tipo enemigo
@export var enemies_node_path: NodePath = NodePath("Enemies")
# Estado de limpieza persistido (se lee desde los datos del mapa al cargar)
@export var cleared: bool = false

# Nodos cacheados de la sala
var doors: Node = null
var spawns: Node = null
var enemies_root: Node = null

# Contador de enemigos vivos en la sala
var _enemies_alive: int = 0
# Flag interno de sala despejada
var _cleared: bool = true
# Evita conectar las señales de enemigos más de una vez
var _enemy_signals_connected: bool = false


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

# Cachea los nodos hijos en cuanto la sala entra al árbol (antes de _ready).
func _enter_tree() -> void:
	doors = get_node_or_null("Doors")
	spawns = get_node_or_null("Spawns")
	enemies_root = get_node_or_null(enemies_node_path)

# Hace el primer conteo de enemigos en el siguiente frame para asegurar que
# todos los hijos estén listos en el árbol.
func _ready() -> void:
	call_deferred("_recount_enemies_and_update_doors")

# Devuelve las capacidades de puerta de esta sala en un diccionario limpio.
func get_door_caps() -> Dictionary:
	return {
		"up": bool(door_caps.get("up", true)),
		"down": bool(door_caps.get("down", true)),
		"left": bool(door_caps.get("left", true)),
		"right": bool(door_caps.get("right", true)),
	}


# =============================================================================
# SETUP (llamado desde el nivel principal al instanciar la sala)
# =============================================================================

# Configura las puertas según los datos del mapa, conecta señales y aplica
# el estado de limpieza guardado (elimina enemigos si la sala ya estaba despejada).
func setup(room_data: Dictionary) -> void:
	if doors == null:
		doors = get_node_or_null("Doors")
	if spawns == null:
		spawns = get_node_or_null("Spawns")
	if enemies_root == null:
		enemies_root = get_node_or_null(enemies_node_path)

	if doors == null:
		return

	_set_door_enabled("Up", "up", room_data)
	_set_door_enabled("Down", "down", room_data)
	_set_door_enabled("Left", "left", room_data)
	_set_door_enabled("Right", "right", room_data)

	_connect_doors_to_room_signal()

	if lock_doors_until_clear:
		_connect_enemy_signals_if_possible()
		call_deferred("_recount_enemies_and_update_doors")
	else:
		_set_all_doors_open(true)

	# Si la sala ya estaba despejada en el save, elimina los enemigos y aplica estado
	var saved_cleared := bool(room_data.get("cleared", false))
	if saved_cleared:
		_remove_all_enemies()
	_apply_cleared_state(saved_cleared)

	# Segunda pasada de configuración de puertas (garantiza coherencia tras apply_cleared)
	if doors == null:
		return

	_set_door_enabled("Up", "up", room_data)
	_set_door_enabled("Down", "down", room_data)
	_set_door_enabled("Left", "left", room_data)
	_set_door_enabled("Right", "right", room_data)

	_connect_doors_to_room_signal()

	if lock_doors_until_clear:
		_connect_enemy_signals_if_possible()
		call_deferred("_recount_enemies_and_update_doors")
	else:
		_set_all_doors_open(true)


# =============================================================================
# CONEXIÓN PUERTAS → SEÑAL DE SALA
# =============================================================================

# Recorre recursivamente el nodo Doors y conecta la señal "entered" de cada
# puerta wrapper al método _on_door_wrapper_entered.
func _connect_doors_to_room_signal() -> void:
	if doors == null:
		return

	var cb := Callable(self, "_on_door_wrapper_entered")
	_connect_doors_recursive(doors, cb)

func _connect_doors_recursive(n: Node, cb: Callable) -> void:
	for c in n.get_children():
		if c == null:
			continue
		if c.has_signal("entered"):
			if not c.is_connected("entered", cb):
				c.connect("entered", cb)
		_connect_doors_recursive(c, cb)

# Re-emite la señal de la sala con la dirección cuando el jugador cruza una puerta.
func _on_door_wrapper_entered(dir: String) -> void:
	emit_signal("door_entered", dir)


# =============================================================================
# HABILITACIÓN DE PUERTAS SEGÚN EL MAPA
# =============================================================================

# Activa o desactiva una puerta concreta según los datos del mapa y las door_caps de la sala.
func _set_door_enabled(node_name: String, key: String, room_data: Dictionary) -> void:
	var door_node := doors.get_node_or_null(node_name)
	if door_node == null:
		return

	# La puerta solo se activa si el mapa la tiene abierta Y la sala la soporta físicamente
	var enabled: bool = bool(room_data.get("doors", {}).get(key, false)) and bool(door_caps.get(key, true))

	if door_node.has_method("set_enabled"):
		door_node.call("set_enabled", enabled)
		return

	# Fallback para puertas que sean Area2D simples sin método set_enabled
	var a := door_node as Area2D
	if a == null:
		return
	a.set_deferred("monitoring", enabled)
	a.set_deferred("monitorable", enabled)


# =============================================================================
# DETECCIÓN DE ENEMIGOS (ABRIR / CERRAR PUERTAS)
# =============================================================================

# Conecta las señales de entrada y salida del nodo Enemies para rastrear
# cuántos enemigos quedan vivos. Solo se conecta una vez.
func _connect_enemy_signals_if_possible() -> void:
	if _enemy_signals_connected:
		return

	if enemies_root == null:
		enemies_root = get_node_or_null(enemies_node_path)
	if enemies_root == null:
		return

	enemies_root.child_entered_tree.connect(Callable(self, "_on_enemy_child_entered"))
	enemies_root.child_exiting_tree.connect(Callable(self, "_on_enemy_child_exiting"))
	_enemy_signals_connected = true

# Recuenta los enemigos vivos y actualiza el estado de las puertas.
# Se llama de forma diferida para asegurar que el árbol esté estable.
func _recount_enemies_and_update_doors() -> void:
	if not lock_doors_until_clear:
		return

	if enemies_root == null:
		enemies_root = get_node_or_null(enemies_node_path)

	_enemies_alive = 0
	if enemies_root != null:
		for c in enemies_root.get_children():
			if c == null:
				continue
			if c.is_in_group("enemy"):
				_enemies_alive += 1

	_cleared = (_enemies_alive <= 0)
	_update_doors_open_state()

# Incrementa el contador cuando un nuevo enemigo entra al nodo Enemies.
func _on_enemy_child_entered(child: Node) -> void:
	if child == null:
		return
	if not child.is_in_group("enemy"):
		return
	_enemies_alive += 1
	_cleared = false
	_update_doors_open_state()

# Decrementa el contador cuando un enemigo sale del nodo Enemies (muerte o queue_free).
func _on_enemy_child_exiting(child: Node) -> void:
	if child == null:
		return
	if not child.is_in_group("enemy"):
		return

	_enemies_alive = max(0, _enemies_alive - 1)
	_cleared = (_enemies_alive <= 0)
	_update_doors_open_state()

# Abre o cierra todas las puertas según el estado de limpieza actual.
func _update_doors_open_state() -> void:
	_set_all_doors_open(_cleared)

# Llama a set_open en cada puerta direccional (Up, Down, Left, Right).
func _set_all_doors_open(open: bool) -> void:
	if doors == null:
		return

	for n in ["Up", "Down", "Left", "Right"]:
		var d := doors.get_node_or_null(n)
		if d == null:
			continue
		if d.has_method("set_open"):
			d.call("set_open", open)


# =============================================================================
# HELPERS DE SPAWN Y POSICIÓN
# =============================================================================

# Devuelve la posición global del punto "Center" del nodo Spawns, o la posición
# del nodo raíz si no existe.
func get_center_global() -> Vector2:
	if spawns == null:
		spawns = get_node_or_null("Spawns")
	if spawns != null:
		var c := spawns.get_node_or_null("Center") as Node2D
		if c != null:
			return c.global_position
	return global_position

# Devuelve el punto de spawn del jugador según la dirección desde la que entró.
# Si no existe el punto específico, usa "Center" como fallback.
func get_spawn_global(entered_from_dir: String) -> Vector2:
	if spawns == null:
		spawns = get_node_or_null("Spawns")
	if spawns == null:
		return global_position

	var spawn_name := "Center"
	match entered_from_dir:
		"up": spawn_name = "FromUp"
		"down": spawn_name = "FromDown"
		"left": spawn_name = "FromLeft"
		"right": spawn_name = "FromRight"
		_: spawn_name = "Center"

	var m := spawns.get_node_or_null(spawn_name) as Node2D
	if m != null:
		return m.global_position

	var c := spawns.get_node_or_null("Center") as Node2D
	if c != null:
		return c.global_position

	return global_position


# =============================================================================
# UTILIDADES DE ESTADO DE SALA
# =============================================================================

# Elimina todos los hijos del nodo Enemies (usado al cargar una sala ya despejada).
func _remove_all_enemies() -> void:
	if enemies_root == null:
		enemies_root = get_node_or_null(enemies_node_path)
	if enemies_root == null:
		return

	for c in enemies_root.get_children():
		if c == null:
			continue
		c.queue_free()

# Aplica el estado de limpieza a los flags internos y abre/cierra las puertas en consecuencia.
func _apply_cleared_state(is_cleared: bool) -> void:
	cleared = is_cleared
	_cleared = is_cleared

	if lock_doors_until_clear:
		_set_all_doors_open(is_cleared)

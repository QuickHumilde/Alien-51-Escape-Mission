extends Node2D
class_name RoomClearItemSpawner

# =============================================================================
# PARÁMETROS EXPORTADOS
# =============================================================================

# Si es false, el spawner está desactivado y no hará nada
@export var activable: bool = true
# Segundos de espera antes de habilitar el hitbox del ítem spawneado
@export var timer: float = 1.25
# Si es true, usa el RNG global de GameManager (para reproducibilidad con seed)
@export var use_global_random: bool = true


# =============================================================================
# ESTADO PERSISTIDO
# =============================================================================

# Indica si ya se ha spawneado un ítem en esta sala (evita spawns múltiples)
var has_spawned: bool = false
# ID del ítem que se spawneó (para restaurarlo al cargar un save)
var spawned_item_id: int = -1
# Indica si el ítem ya fue recogido por el jugador
var was_picked: bool = false


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	# Si el spawner no es activable, lo desactiva completamente
	if not is_activable():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	Signals.room_cleared.connect(_on_room_cleared)


# =============================================================================
# API DE GUARDADO (SAVE SYSTEM)
# =============================================================================

# Devuelve una clave única para identificar este spawner en el save.
func get_spawner_key() -> String:
	return str(get_path())

# Serializa el estado actual del spawner para guardarlo.
func get_save_state() -> Dictionary:
	return {
		"has_spawned": has_spawned,
		"spawned_item_id": spawned_item_id,
		"was_picked": was_picked,
	}

# Restaura el estado del spawner desde un save:
# - Si el ítem ya fue recogido, elimina los hijos y no hace nada más.
# - Si ya había spawneado, reinstancia el ítem específico.
func load_save_state(state: Dictionary) -> void:
	has_spawned = bool(state.get("has_spawned", false))
	spawned_item_id = int(state.get("spawned_item_id", -1))
	was_picked = bool(state.get("was_picked", false))

	if was_picked:
		for c in get_children():
			c.queue_free()
		return

	if has_spawned and spawned_item_id >= 0:
		for c in get_children():
			c.queue_free()
		_spawn_specific_item(spawned_item_id)


# =============================================================================
# LÓGICA DE SPAWN
# =============================================================================

# Callback de la señal room_cleared: lanza el spawn diferido si la sala
# está activa y el ítem no ha aparecido ni sido recogido antes.
func _on_room_cleared() -> void:
	var room: Node = get_parent()
	if room != null and room.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	if has_spawned or was_picked:
		return
	call_deferred("_spawn_item_deferred")

# Elige un ítem aleatorio del pool y lo spawna. Llamado diferido para
# asegurar que el árbol de escena esté estable tras el room_cleared.
func _spawn_item_deferred() -> void:
	if has_spawned or was_picked:
		return
	# Si ya tiene hijos (spawneado antes de este frame), lo marca como hecho
	if get_child_count() > 0:
		has_spawned = true
		return
	if ItemManager.item_pool.is_empty():
		return

	var rng := GameManager.rng
	var item_id: int = ItemManager.pick_random_item_id(rng)
	if item_id < 0:
		return

	spawned_item_id = item_id
	has_spawned = true
	_spawn_specific_item(item_id)
	# Marca el ítem como usado en el pool para no volver a ofrecerlo
	ItemManager.mark_removed(item_id)

# Instancia el ítem con el ID indicado, lo posiciona en el spawner
# y habilita su hitbox tras el tiempo de espera configurado.
func _spawn_specific_item(item_id: int) -> void:
	# Evita duplicados si ya hay un hijo presente
	if get_child_count() > 0:
		return
	var ps: PackedScene = ItemManager.get_scene(item_id)
	if ps == null:
		return

	var inst = ps.instantiate()
	add_child(inst)
	# Desactiva el hitbox inicialmente para evitar recogida instantánea
	if inst.has_method("disable_hitbox"):
		inst.disable_hitbox()
	if inst is Node2D:
		(inst as Node2D).global_position = global_position

	# Espera el timer antes de habilitar la recogida
	await get_tree().create_timer(timer).timeout
	if inst != null and is_instance_valid(inst) and inst.has_method("enable_hitbox"):
		inst.enable_hitbox()


# =============================================================================
# UTILIDADES
# =============================================================================

# Marca el ítem como recogido y elimina sus nodos hijos.
func mark_picked() -> void:
	was_picked = true
	for c in get_children():
		c.queue_free()

# Devuelve si este spawner está configurado como activable.
func is_activable() -> bool:
	return activable

extends Node
class_name ScytheAbility

# Señales para sincronizar la barra de cooldown del HUD
signal cooldown_started(duration: float)
signal cooldown_progress(progress: float)
signal cooldown_finished()

# =============================================================================
# PARÁMETROS EXPORTADOS
# =============================================================================

# Duración del cooldown en segundos
@export var cooldown: float = 6.0
# Escena del proyectil que dispara la guadaña
@export var bullet_scene: PackedScene = preload("res://scenes/bullets/scythe_bullet.tscn")

# Parámetros de los proyectiles disparados
@export var bullet_damage: float = 1.0
@export var bullet_knockback: float = 250.0
@export var bullet_lifetime: float = 1.2
@export var bullet_speed: float = 100.0

# Distancia desde el jugador al origen de cada proyectil
@export var spawn_offset: float = 5.0

# Indica si la habilidad está en cooldown y no puede usarse
var is_on_cooldown: bool = false
# Referencia al jugador propietario de esta habilidad
var player: Character = null
# Timestamp en ms del fin del cooldown (para calcular tiempo restante)
var _cooldown_end_ms: int = 0


# =============================================================================
# ICONO Y REFERENCIA AL JUGADOR
# =============================================================================

# Devuelve la ruta de la textura del icono para el HUD.
func get_icon_path() -> String:
	return "res://assets/sprites/items/ScytheItem.png"

# Asigna la referencia al jugador (llamado desde CharacterAbilities al equipar).
func get_player(body: Character) -> void:
	player = body


# =============================================================================
# ACTIVACIÓN
# =============================================================================

# Activa la habilidad si no está en cooldown: dispara 8 proyectiles y arranca el timer.
func activate_with_player(_player: Character) -> void:
	# Robustez: asigna el jugador si aún no estaba seteado
	if player == null or not is_instance_valid(player):
		player = _player
	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		return

	if is_on_cooldown:
		return

	is_on_cooldown = true
	emit_signal("cooldown_started", cooldown)
	emit_signal("cooldown_progress", 0.0)

	_fire_8(player)
	_play_sound()

	start_cooldown_timer(player)


# =============================================================================
# DISPARO EN 8 DIRECCIONES
# =============================================================================

# Instancia y lanza 8 proyectiles en las 4 direcciones cardinales y 4 diagonales.
# El daño de cada proyectil suma el daño base más el daño del jugador.
func _fire_8(_player: Character) -> void:
	var dirs: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
		Vector2.DOWN,
		(Vector2.RIGHT + Vector2.UP).normalized(),
		(Vector2.RIGHT + Vector2.DOWN).normalized(),
		(Vector2.LEFT + Vector2.UP).normalized(),
		(Vector2.LEFT + Vector2.DOWN).normalized(),
	]

	for d in dirs:
		var b := bullet_scene.instantiate()
		player.get_tree().current_scene.add_child(b)

		var spawn_pos := player.global_position + d * spawn_offset
		var bullet_owner = "player"

		if b.has_method("init"):
			b.init(
				d,
				spawn_pos,
				bullet_damage + player.stats.get_damage(),
				bullet_knockback,
				bullet_lifetime,
				bullet_speed,
				bullet_owner
			)
		else:
			b.global_position = spawn_pos


# =============================================================================
# COOLDOWN
# =============================================================================

# Crea dos timers en el jugador: tick (progreso HUD cada 0.05 s) y end_timer (fin cooldown).
# Ambos se limpian solos al terminar o si el jugador sale del árbol.
func start_cooldown_timer(_player: Node) -> void:
	_cooldown_end_ms = Time.get_ticks_msec() + int(cooldown * 1000.0)

	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		is_on_cooldown = false
		return

	var end_timer: Timer = Timer.new()
	end_timer.one_shot = true
	end_timer.wait_time = cooldown
	end_timer.process_mode = Node.PROCESS_MODE_PAUSABLE

	var tick: Timer = Timer.new()
	tick.one_shot = false
	tick.wait_time = 0.05
	tick.process_mode = Node.PROCESS_MODE_PAUSABLE

	player.add_child(end_timer)
	player.add_child(tick)

	var started_at := Time.get_ticks_msec()
	var cooldown_ms := int(cooldown * 1000.0)

	# Actualiza la barra de cooldown del HUD en cada tick
	tick.timeout.connect(func ():
		if not is_instance_valid(end_timer):
			return
		var elapsed_ms := Time.get_ticks_msec() - started_at
		var progress = clamp(float(elapsed_ms) / float(cooldown_ms), 0.0, 1.0)
		emit_signal("cooldown_progress", progress)
	)

	# Al terminar el cooldown, limpia los timers y notifica al HUD
	end_timer.timeout.connect(func ():
		if is_instance_valid(tick):
			tick.stop()
			tick.queue_free()

		is_on_cooldown = false
		emit_signal("cooldown_progress", 1.0)
		emit_signal("cooldown_finished")

		end_timer.queue_free()
	)

	# Si el jugador sale del árbol, cancela los timers para evitar errores
	player.tree_exited.connect(func ():
		if is_instance_valid(end_timer):
			end_timer.stop()
			end_timer.queue_free()
		if is_instance_valid(tick):
			tick.stop()
			tick.queue_free()
		is_on_cooldown = false
	, CONNECT_ONE_SHOT)

	tick.start()
	end_timer.start()


# =============================================================================
# GUARDADO Y CARGA
# =============================================================================

# Serializa el estado del cooldown para el sistema de save.
func get_save_state() -> Dictionary:
	return {
		"is_on_cooldown": is_on_cooldown,
		"cooldown_remaining": get_cooldown_remaining()
	}

# Restaura el cooldown desde un save: si quedaba tiempo, reanuda el timer;
# si no, emite cooldown_finished para que el HUD muestre la habilidad lista.
func load_save_state(state: Dictionary) -> void:
	var rem := float(state.get("cooldown_remaining", 0.0))
	if rem > 0.0:
		is_on_cooldown = true
		emit_signal("cooldown_started", rem)
		emit_signal("cooldown_progress", 0.0)
		_start_cooldown_with_remaining(player, rem)
	else:
		is_on_cooldown = false
		emit_signal("cooldown_progress", 1.0)
		emit_signal("cooldown_finished")

# Devuelve los segundos restantes del cooldown (0.0 si no está activo).
func get_cooldown_remaining() -> float:
	if not is_on_cooldown:
		return 0.0
	return max(0.0, float(_cooldown_end_ms - Time.get_ticks_msec()) / 1000.0)

# Inicia un cooldown con el tiempo restante del save usando un cooldown temporal.
func _start_cooldown_with_remaining(_player: Node, remaining: float) -> void:
	var old := cooldown
	cooldown = remaining
	start_cooldown_timer(player)
	cooldown = old


# =============================================================================
# CAMBIO DE HABILIDAD Y AUDIO
# =============================================================================

# Al cambiar de habilidad, suelta el ítem físico en el mundo y destruye este nodo.
# También restaura el color y la velocidad del jugador por si quedaron alterados.
func change_ability(new_ability_position):
	var item_scene: PackedScene = load("res://scenes/items/scythe_ability_item.tscn")
	var inst = item_scene.instantiate()
	player.get_tree().current_scene.add_child(inst)
	inst.global_position = new_ability_position
	inst.disable_pickup(2.0)
	player.animation.player_and_weapon_changing_color(Color(1,1,1), Color(1,1,1))
	player.movement.clear_override_speed()
	queue_free()

# Reproduce el SFX de la guadaña con pitch aleatorio leve.
func _play_sound() -> void:
	var pitch: float = randf_range(0.95, 1.1)
	AudioManager.play_sfx("scythe_1", -2.0, pitch)

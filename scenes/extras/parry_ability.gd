extends Node
class_name ParryAbility

# =============================================================================
# REFERENCIAS Y PARÁMETROS
# =============================================================================

# Área que detecta enemigos y balas al activar el parry
@onready var area: Area2D = $Area2D

# Daño aplicado a los enemigos en rango al hacer parry con éxito
@export var damage: float = 2.0

# Señales para sincronizar la barra de cooldown del HUD
signal cooldown_started(duration: float)
signal cooldown_progress(progress: float)
signal cooldown_finished()

# Duración del cooldown en segundos
var cooldown: float = 4.0
# Indica si la habilidad está en cooldown y no puede usarse
var is_on_cooldown: bool = false
# Indica si el parry no golpeó nada (afecta al SFX reproducido)
var failed: bool = true
# Timestamp en ms del momento en que termina el cooldown (para calcular tiempo restante)
var _cooldown_end_ms: int = 0

# Referencia al jugador propietario de esta habilidad
var player: Character = null


# =============================================================================
# ICONO Y ESCENA
# =============================================================================

# Devuelve la ruta de la textura usada en el HUD para esta habilidad.
func get_icon_path() -> String:
	return "res://assets/sprites/items/ParryAbility.png"

# Devuelve la ruta de la escena instanciable de esta habilidad.
func get_ability_scene_path() -> String:
	return "res://scenes/extras/parry_ability_scene.tscn"


# =============================================================================
# ACTIVACIÓN
# =============================================================================

# Activa el parry si el jugador puede recibir daño y la habilidad no está en cooldown.
# Emite las señales de inicio de cooldown, ejecuta el parry y arranca el timer.
func activate_with_player(_player: Character):
	# Robustez: asigna el jugador si aún no estaba seteado
	if player == null or not is_instance_valid(player):
		player = _player
	if player == null or not is_instance_valid(player):
		return
	if not player.is_player_damagable():
		return
	if is_on_cooldown:
		return

	is_on_cooldown = true
	failed = true

	emit_signal("cooldown_started", cooldown)
	emit_signal("cooldown_progress", 0.0)

	start_parry(player)
	play_sfx()
	start_cooldown_timer(player)


# =============================================================================
# COOLDOWN
# =============================================================================

# Crea dos timers en el jugador: uno de tick (para actualizar el progreso en el HUD)
# y uno final (para marcar el fin del cooldown). Ambos se limpian solos al terminar.
func start_cooldown_timer(_player: Node) -> void:
	_cooldown_end_ms = Time.get_ticks_msec() + int(cooldown * 1000.0)
	is_on_cooldown = true

	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		is_on_cooldown = false
		return

	var end_timer := Timer.new()
	end_timer.one_shot = true
	end_timer.wait_time = cooldown
	end_timer.process_mode = Node.PROCESS_MODE_PAUSABLE

	# Timer de tick: emite cooldown_progress cada 0.05 s
	var tick := Timer.new()
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

	# Al terminar el cooldown, limpia los timers y emite cooldown_finished
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
# LÓGICA DEL PARRY
# =============================================================================

# Comprueba las áreas solapadas en el momento del parry:
# - Enemigos: reciben knockback y daño.
# - Balas: se redirigen hacia el jugador como origen (pasan a ser del equipo jugador).
func start_parry(_player: Character):
	if area == null or not is_instance_valid(area):
		return

	var overlapping_bodies = area.get_overlapping_areas()
	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			failed = false
			if body.has_method("apply_knockback"):
				var knockback_direction = (body.global_position - player.global_position).normalized()
				body.apply_knockback(knockback_direction, 350.0)
			if body.has_method("take_damage"):
				body.take_damage(damage)

		if body.is_in_group("bullet"):
			failed = false
			var new_direction = (player.global_position - body.global_position).normalized()
			body.change_direction(new_direction, "player")


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

# Devuelve los segundos restantes del cooldown actual (0.0 si no está en cooldown).
func get_cooldown_remaining() -> float:
	if not is_on_cooldown:
		return 0.0
	return max(0.0, float(_cooldown_end_ms - Time.get_ticks_msec()) / 1000.0)

# Inicia un cooldown con el tiempo restante guardado en el save,
# reutilizando start_cooldown_timer con un cooldown temporal.
func _start_cooldown_with_remaining(_player: Node, remaining: float) -> void:
	var old := cooldown
	cooldown = remaining
	start_cooldown_timer(player)
	cooldown = old


# =============================================================================
# UTILIDADES
# =============================================================================

# Asigna la referencia al jugador (llamado desde CharacterAbilities al equipar).
func get_player(body: Character):
	player = body

# Al cambiar de habilidad, suelta el ítem físico en el mundo en la posición indicada
# y destruye este nodo.
func change_ability(new_ability_position):
	var item_scene: PackedScene = load("res://scenes/items/parry_ability_item.tscn")
	var inst = item_scene.instantiate()
	get_tree().current_scene.add_child(inst)
	inst.global_position = new_ability_position
	inst.disable_pickup(2.0)
	queue_free()

# Reproduce el SFX de parry: exitoso o fallido, con pitch aleatorio leve.
func play_sfx():
	var pitch: float = randf_range(0.9, 1.1)
	if failed:
		AudioManager.play_sfx("failed_parry_1", -10, pitch)
	else:
		AudioManager.play_sfx("parry_1", -10, pitch)

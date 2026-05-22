extends Node
class_name CharacterAnimation

# =============================================================================
# VARIABLES DE ESTADO
# =============================================================================

# Sprite animado del personaje
var sprite: AnimatedSprite2D
# Nodo padre de las armas (se tintará junto al sprite al recibir daño)
var weapon_holder: Node2D
# Dirección cardinal actual del personaje (determina la animación a reproducir)
var cardinal_direction: Vector2 = Vector2.DOWN
# Estado de animación actual: "idle", "walk", "fly" o "vessel"
var state: String = "idle"
# Timer de invulnerabilidad; se usa para saber cuánto dura el efecto de daño
var damage_timer: Timer
# Flag que activa la animación de vuelo
var is_flying: bool = false
# Flag especial que fuerza el estado "vessel" (código secreto)
var vessel: bool = false
# Dirección suavizada (reservada para interpolaciones futuras)
var smooth_dir: Vector2 = Vector2.ZERO


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func init(player_sprite: AnimatedSprite2D, timer: Timer, weaponholder: Node2D):
	sprite = player_sprite
	damage_timer = timer
	weapon_holder = weaponholder
	# Conecta la señal del código secreto vessel
	Signals.vessel_code.connect(vessel_code)


# =============================================================================
# ACTUALIZACIÓN POR FRAME
# =============================================================================

# Comprueba si cambia el estado o la dirección y, si alguno cambió, reproduce
# la animación correspondiente con el formato "estado_dirección" (ej: "walk_side").
func update(character):
	if set_state(character) or set_direction(character):
		sprite.play(state + "_" + anim_direction())


# =============================================================================
# DIRECCIÓN Y ESTADO
# =============================================================================

# Calcula la nueva dirección cardinal a partir de la velocidad del personaje.
# Devuelve true si la dirección cambió (para saber si hay que actualizar la animación).
# También aplica el flip horizontal cuando el personaje mira a la izquierda.
func set_direction(character) -> bool:
	var vel = character.velocity
	if vel == Vector2.ZERO:
		return false
	var new_direction: Vector2
	if abs(vel.x) > abs(vel.y):
		new_direction = Vector2.LEFT if vel.x < 0 else Vector2.RIGHT
	else:
		new_direction = Vector2.UP if vel.y < 0 else Vector2.DOWN
	if new_direction == cardinal_direction:
		return false
	cardinal_direction = new_direction
	character.sprite.flip_h = (cardinal_direction == Vector2.LEFT)
	return true

# Determina el estado de animación según las flags activas y la velocidad del personaje.
# Prioridad: vessel > fly > walk/idle.
# Devuelve true si el estado cambió.
func set_state(character) -> bool:
	var new_state: String
	if vessel:
		new_state = "vessel"
	elif is_flying:
		new_state = "fly"
	else:
		new_state = "idle" if character.velocity == Vector2.ZERO else "walk"
	if new_state == state:
		return false
	state = new_state
	return true

# Convierte la dirección cardinal actual a la cadena usada en el nombre de la animación.
# Izquierda y derecha comparten el sufijo "side" (el flip se maneja por código).
func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"


# =============================================================================
# EFECTOS VISUALES DE DAÑO Y MUERTE
# =============================================================================

# Reproduce el efecto de parpadeo rojo mientras dura el timer de invulnerabilidad.
# Alterna entre rojo intenso y blanco cada 0.1 segundos.
func player_taking_damage():
	if !Signals.player_is_dead:
		player_and_weapon_changing_color(Color(1, 0, 0, 1), Color(1, 0, 0, 1))
		damage_timer.start()

		while (!damage_timer.is_stopped()):
			await get_tree().create_timer(0.1).timeout
			player_and_weapon_changing_color(Color(0.431, 0.0, 0.0, 0.0), Color(0.431, 0.0, 0.0, 0.0))
			await get_tree().create_timer(0.1).timeout
			player_and_weapon_changing_color(Color(1, 1, 1), Color(1, 1, 1))

		damage_timer.stop()

# Reproduce la animación de muerte y, tras terminar, decide si revivir o mostrar
# el menú de muerte según el número de revives disponibles.
func player_dying(player_revives: int):
	# PROCESS_MODE_ALWAYS garantiza que la animación se reproduce aunque el árbol pause
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.play("dying")
	await sprite.animation_finished

	if player_revives > 0:
		player_revive()
	else:
		Signals.show_death_menu.emit()
		sprite.process_mode = Node.PROCESS_MODE_INHERIT

# Emite la señal de revive y vuelve a la animación idle mirando hacia abajo.
func player_revive():
	Signals.player_revive.emit()
	sprite.play("idle_down")


# =============================================================================
# UTILIDADES DE COLOR
# =============================================================================

# Cambia el tinte del sprite del jugador.
func player_changing_color(player_color: Color):
	sprite.modulate = player_color

# Cambia el tinte del sprite y del weapon_holder simultáneamente.
func player_and_weapon_changing_color(player_color: Color, weapon_holder_color: Color):
	sprite.modulate = player_color
	weapon_holder.modulate = weapon_holder_color


# =============================================================================
# CÓDIGO SECRETO VESSEL
# =============================================================================

# Activa el estado especial "vessel" al recibir la señal correspondiente.
func vessel_code():
	print("VESSEL CODE: ACTIVATED")
	vessel = true

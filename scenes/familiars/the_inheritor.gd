extends Node2D
class_name BasicFamiliar

# =============================================================================
# PARÁMETROS DE ÓRBITA
# =============================================================================

# Radio en píxeles al que el familiar orbita alrededor del jugador
@export var orbit_radius: float = 15.0
# Velocidad angular de la órbita en radianes por segundo
@export var orbit_speed: float = 0.5
# Factor de suavizado del seguimiento (mayor = más rápido)
@export var follow_lerp: float = 12.0
# Distancia desde el familiar al origen de los proyectiles disparados
@export var spawn_offset: float = 10.0


# =============================================================================
# VARIABLES DE ESTADO
# =============================================================================

# Referencia al jugador al que sigue el familiar
var _player: CharacterBody2D = null
# Acumulador de tiempo para calcular la posición orbital
var _t: float = 0.0
# Cuenta regresiva hasta el próximo disparo
var _shoot_t: float = 0.0


# =============================================================================
# PARÁMETROS DE COMBATE
# =============================================================================

# Escena del proyectil que dispara el familiar
var bullet_scene: PackedScene = null
# Segundos entre disparos
var shoot_interval: float = 1.5
# Distancia máxima a la que el familiar detecta enemigos
var target_range: float = 100.0
# Daño de cada proyectil
var bullet_damage: float = 1.0
# Velocidad del proyectil en píxeles por segundo
var bullet_speed: float = 200.0
# Tiempo de vida del proyectil en segundos
var bullet_lifetime: float = 0.75
# Fuerza de knockback aplicada al enemigo al impactar
var bullet_knockback: float = 120.0


# =============================================================================
# INICIALIZACIÓN Y CONFIGURACIÓN
# =============================================================================

# Asigna la referencia al jugador al que pertenece este familiar.
func init(player: CharacterBody2D) -> void:
	_player = player

# Aplica parámetros de combate desde un diccionario (usado al instanciar desde ítems).
func configure(data: Dictionary) -> void:
	if data.has("bullet_scene"): bullet_scene = data["bullet_scene"]
	if data.has("shoot_interval"): shoot_interval = float(data["shoot_interval"])
	if data.has("target_range"): target_range = float(data["target_range"])
	if data.has("bullet_damage"): bullet_damage = float(data["bullet_damage"])
	if data.has("bullet_speed"): bullet_speed = float(data["bullet_speed"])
	if data.has("bullet_lifetime"): bullet_lifetime = float(data["bullet_lifetime"])
	if data.has("bullet_knockback"): bullet_knockback = float(data["bullet_knockback"])


# =============================================================================
# BUCLE PRINCIPAL
# =============================================================================

# Mueve el familiar en órbita alrededor del jugador e intenta disparar
# cada shoot_interval segundos. Se destruye si el jugador deja de ser válido.
func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return

	# Calcula la posición orbital usando funciones trigonométricas
	_t += delta
	var orbit := Vector2(cos(_t * orbit_speed), sin(_t * orbit_speed)) * orbit_radius
	var desired := _player.global_position + orbit
	global_position = global_position.lerp(desired, clamp(follow_lerp * delta, 0.0, 1.0))

	# Cuenta regresiva del intervalo de disparo
	_shoot_t -= delta
	if _shoot_t <= 0.0:
		_shoot_t = shoot_interval
		_try_shoot()


# =============================================================================
# DISPARO
# =============================================================================

# Busca el enemigo más cercano y dispara un proyectil hacia él si hay objetivo válido.
func _try_shoot() -> void:
	if bullet_scene == null:
		return
	var enemy := _find_target()
	if enemy == null:
		return

	var to_enemy = enemy.global_position - global_position
	if to_enemy.length_squared() < 0.0001:
		return

	var dir = to_enemy.normalized()
	var b = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	var spawn_pos = global_position + dir * spawn_offset

	if b.has_method("init"):
		b.init(
			dir,
			spawn_pos,
			bullet_damage,
			bullet_knockback,
			bullet_lifetime,
			bullet_speed,
			"player"   # El propietario es el jugador para evitar daño propio
		)
	else:
		b.global_position = spawn_pos


# =============================================================================
# DETECCIÓN DE OBJETIVOS
# =============================================================================

# Recorre todos los nodos del grupo "enemy" y devuelve el más cercano dentro
# de target_range. Usa distancia al cuadrado para evitar raíces cuadradas.
func _find_target() -> Node2D:
	var best: Node2D = null
	var best_d2 := target_range * target_range
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Node2D
		if e == null or not is_instance_valid(e):
			continue
		var d2 := global_position.distance_squared_to(e.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = e
	return best

extends Node
class_name CharacterStats

signal stats_changed

# =============================================================================
# VARIABLES BASE (VALORES SIN MODIFICADORES)
# =============================================================================

# Estos son los valores "puros" del personaje antes de aplicar bonus de ítems.
# Los getters siempre devuelven el valor cacheado (base + modificadores).
@export var max_health: float = 5.0
@export var health: float = 0.0
@export var extra_health: float = 0          # Escudo/salud extra (se consume antes que health)
@export var speed: float = 75.0
@export var size: float = 1.0
@export var extra_damage: float = 0.0
@export var extra_lifetime: float = 0.0      # Modificador de duración de proyectiles
@export var invulnerability_time: float = 1.0
@export var is_flying: bool = false
@export var revives: int = 0


# =============================================================================
# REFERENCIAS A COMPONENTES DEL JUGADOR
# =============================================================================

@onready var player_inventory: PlayerInventory
@onready var player_audio: CharacterAudio
@onready var player_animation: CharacterAnimation
@onready var sprite: AnimatedSprite2D
@onready var player_collision_detector: CollisionShape2D
@onready var player_hitbox: CollisionShape2D
@onready var player_tramp_collision_detector: CollisionShape2D
@onready var visuals: Node2D


# =============================================================================
# CACHÉ DE STATS CALCULADAS
# =============================================================================

# Flag que indica si el caché está desactualizado y hay que recalcular
var stats_variated: bool = true

# Valores finales (base + suma de modificadores de ítems); se recalculan con recalc_stats()
var cached_speed: float
var cached_damage: float
var cached_size: float
var cached_max_health: float
var cached_lifetime: float
var cached_invulnerability: float


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

# Asigna todas las referencias de componentes y establece la salud inicial al máximo.
func init(cSprite: AnimatedSprite2D, audio:CharacterAudio, animation: CharacterAnimation, detector: CollisionShape2D, hitbox: CollisionShape2D, cVisuals: Node2D, tramp_hitbox: CollisionShape2D, inventory: PlayerInventory) -> void:
	health = max_health
	sprite = cSprite
	player_audio = audio
	player_animation = animation
	player_collision_detector = detector
	player_hitbox = hitbox
	visuals = cVisuals
	player_tramp_collision_detector = tramp_hitbox
	player_inventory = inventory
	stats_variated = true

func _ready() -> void:
	# Emite el estado inicial de salud para que el HUD se actualice al arrancar
	Signals.health_changed.emit(health, max_health, extra_health, revives)
	# Cualquier cambio global de stats invalida el caché
	Signals.stats_changed.connect(_invalidate_stats)


# =============================================================================
# RECÁLCULO Y CACHÉ DE STATS
# =============================================================================

# Recalcula todas las stats sumando los bonus de cada modificador activo en el inventario.
# Aplica mínimos de seguridad y actualiza el tamaño visual del personaje.
func recalc_stats():
	# Parte de los valores base
	cached_speed = speed
	cached_damage = extra_damage
	cached_size = size
	cached_max_health = max_health
	cached_lifetime = extra_lifetime
	cached_invulnerability = invulnerability_time

	# Acumula los bonus de cada ítem/modificador equipado
	for mod in player_inventory.get_modifiers():
		if mod.has_method("get_bonus"):
			cached_speed += mod.get_bonus("speed", self)
			cached_damage += mod.get_bonus("damage", self)
			cached_size += mod.get_bonus("size", self)
			cached_max_health += mod.get_bonus("max_health", self)
			cached_lifetime += mod.get_bonus("lifetime", self)
			cached_invulnerability += mod.get_bonus("invulnerability_time", self)

	# Aplica valores mínimos para evitar estados imposibles
	if cached_invulnerability < 0.05:
		cached_invulnerability = 0.05

	if cached_size < 0.1:
		cached_size = 0.1

	if cached_damage < 0:
		cached_damage = 0

	_apply_size_visual(cached_size)
	stats_variated = false
	emit_signal("stats_changed")
	Signals.update_hud_stats.emit()


# =============================================================================
# GETTERS DE STATS (CON LAZY RECÁLCULO)
# =============================================================================

# Cada getter comprueba si el caché es válido y recalcula solo si es necesario.

func get_speed() -> float:
	if stats_variated:
		recalc_stats()
	return cached_speed

func get_damage() -> float:
	if stats_variated:
		recalc_stats()
	return cached_damage

func get_size() -> float:
	if stats_variated:
		recalc_stats()
	return cached_size

func get_max_health() -> float:
	if stats_variated:
		recalc_stats()
	return cached_max_health

func get_lifetime() -> float:
	if stats_variated:
		recalc_stats()
	return cached_lifetime

func get_invulnerability_time() -> float:
	if stats_variated:
		recalc_stats()
	return cached_invulnerability

# Marca el caché como desactualizado para forzar un recálculo en el siguiente getter.
func _invalidate_stats():
	stats_variated = true


# =============================================================================
# DAÑO Y CURACIÓN
# =============================================================================

# Aplica daño al personaje: consume primero el escudo (extra_health) y luego la salud base.
func take_damage(amount: float):
	if extra_health <= 0.0:
		health -= amount
	elif extra_health >= amount:
		extra_health -= amount
	else:
		# El daño supera el escudo: el exceso va a la salud base
		var rest = amount - extra_health
		extra_health = 0.0
		health -= rest

	_emit_health_changed_signal()
	_invalidate_stats()

	if health <= 0.0:
		die()

# Cura al personaje hasta el máximo de salud base.
# Devuelve true si la curación fue efectiva.
func heal(amount: float) -> bool:
	var healed := false

	if amount > 0 and health < max_health:
		var before := health
		health = min(health + amount, max_health)

		if health > before:
			_emit_health_changed_signal()
			healed = true
			_invalidate_stats()

	return healed

# Aumenta la salud máxima base en la cantidad indicada.
func increase_max_health(amount: float):
	max_health += amount
	_emit_health_changed_signal()
	_invalidate_stats()

# Aumenta el escudo (extra_health) en la cantidad indicada.
func increase_extra_health(amount: float):
	extra_health += amount
	_emit_health_changed_signal()
	_invalidate_stats()


# =============================================================================
# MODIFICADORES DE STATS BASE
# =============================================================================

# Suma al valor base de velocidad (los modificadores de ítems se aplican encima en recalc_stats).
func modify_speed(amount: float):
	speed += amount
	_invalidate_stats()

# Suma al valor base de tamaño.
func modify_size(amount: float):
	size += amount
	_invalidate_stats()

# Aumenta el contador de revives (se guarda como int).
func modify_revives(amount: float):
	revives += int(amount)
	_emit_health_changed_signal()

# Activa o desactiva el modo vuelo en el personaje y su animación.
func player_fly(fly : bool):
	if fly and !is_flying:
		is_flying=true
		player_animation.is_flying=true
	elif !fly and is_flying:
		is_flying=false


# =============================================================================
# SEÑALES DE SALUD
# =============================================================================

# Emite la señal global health_changed con el estado actual de salud del jugador.
func _emit_health_changed_signal():
	Signals.health_changed.emit(health, max_health, extra_health, get_revives())


# =============================================================================
# MUERTE Y REVIVE
# =============================================================================

# Gestiona la muerte: reproduce efectos, emite señal y comprueba si el inventario
# permite un revive automático.
func die():
	player_audio.play_death()
	player_animation.player_dying(get_revives())
	Signals.player_death.emit()

	var returns: Array
	returns = player_inventory.can_revive()
	if !returns.is_empty() and returns[0] == true:
		if returns.size() > 1:
			revive(returns[1])
		else:
			revive()

# Espera a que termine la animación de muerte y resucita al jugador con salud reducida.
# Si new_health es -1 usa el valor por defecto (2 de salud).
func revive(new_health: float = -1):
	await player_animation.sprite.animation_finished
	Signals.player_revive.emit()

	# Penaliza la salud máxima al revivir si es suficientemente alta
	if max_health >= 3:
		max_health -= 1

	if new_health != -1 and new_health > 0:
		health = new_health
		if health > max_health:
			health = max_health
	else:
		health = 2

	_emit_health_changed_signal()
	_invalidate_stats()

# Devuelve true si el jugador tiene la salud al máximo (sin contar extra_health).
func is_player_full_healed():
	return health == max_health


# =============================================================================
# TAMAÑO VISUAL
# =============================================================================

# Aplica el tamaño calculado a los nodos visuales y de colisión del personaje.
# El hitbox solo escala cuando el tamaño es menor o igual a 1 (para no agrandar el área de golpe).
func _apply_size_visual(final_size: float):
	visuals.scale = Vector2(final_size, final_size)
	player_collision_detector.scale = Vector2(final_size, final_size)
	player_tramp_collision_detector.scale = Vector2(final_size, final_size)

	if final_size <= 1:
		player_hitbox.scale = Vector2(final_size, final_size)


# =============================================================================
# UTILIDADES
# =============================================================================

# Delega la consulta de revives al inventario (fuente de verdad de los revives disponibles).
func get_revives():
	return player_inventory.get_revives()

# Reduce la salud máxima sin bajar de 1; ajusta la salud actual si supera el nuevo máximo.
func decrease_max_health(quantity: float):
	if max_health - quantity >= 1:
		max_health -= quantity
	else:
		max_health=1

	if health > max_health:
		health=max_health
	_emit_health_changed_signal()

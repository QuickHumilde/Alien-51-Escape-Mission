@abstract
extends CharacterBody2D
class_name Enemy

# =============================================================================
# VARIABLES BASE (EXPORTADAS)
# =============================================================================

# ID numérico del enemigo (usado por el sistema de spawn y recompensas)
@export var id: int
# Velocidad de movimiento en píxeles por segundo
@export var speed: float = 50.0
# Puntos de vida
@export var health: float = 3.0
# Daño aplicado al jugador por contacto
@export var contact_damage: float = 0.0
# Tiempo en segundos que el enemigo permanece congelado tras spawnear
@export var spawn_freeze_time: float = 0.75
# Fuerza del knockback que este enemigo aplica al jugador
@export var knockback_force: float = 0.0


# =============================================================================
# REFERENCIAS A NODOS
# =============================================================================

@onready var player: CharacterBody2D = get_tree().current_scene.get_node("Player")
@onready var visuals: Node2D = $Visual
@onready var sfx_enemy: AudioStreamPlayer2D
# Color de tinte aplicado al recibir daño
@onready var damage_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@onready var navigation: NavigationAgent2D = $NavigationAgent2D
# Controlador de efectos de estado (veneno, ralentización, etc.)
@onready var effects: EffectController = EffectController.new()


# =============================================================================
# VARIABLES DE ESTADO INTERNO
# =============================================================================

# Flag que bloquea el movimiento (spawn, efectos externos, etc.)
var _frozen: bool = false
# Vector de impulso actual del knockback
var knockback: Vector2
# Tiempo restante del knockback en segundos
var knockback_time: float = 0.0
# Umbral mínimo de fuerza que debe superar un knockback para aplicarse
var knockback_resistance: float = 0.0
# Flag que evita solapar efectos de cambio de color
var can_change_color: bool = true
# Duración del tinte de color especial en segundos
var color_time: float = 3.0
# Cooldown antes de poder volver a cambiar de color
var color_time_cooldown: float = 9.0
# Contador de ticks de daño simultáneos (para gestionar el color de daño correctamente)
var damage_ticks: int = 0

# Diccionario de sonidos precargados del enemigo
var sounds: Dictionary = {
	"damage": preload("res://assets/audio/sfx/enemies/stalkerenemy/StalkerDamage.mp3")
}


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	add_child(effects)
	effects.init(self)
	setup_audio()
	navigation.radius = 3.0
	health = GameManager.calculate_enemy_health(health)
	# Congela el enemigo brevemente al aparecer para evitar daño instantáneo al spawn
	if spawn_freeze_time > 0.0:
		freeze_for(spawn_freeze_time)


# =============================================================================
# CONGELADO
# =============================================================================

# Congela el enemigo durante los segundos indicados y luego lo descongela.
func freeze_for(seconds: float) -> void:
	_frozen = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(seconds).timeout
	_frozen = false

# Devuelve true si el enemigo está congelado.
func is_frozen() -> bool:
	return _frozen

# Detiene el movimiento mientras el enemigo está congelado y aplica move_and_slide.
func process_frozen() -> void:
	velocity = Vector2.ZERO
	move_and_slide()


# =============================================================================
# KNOCKBACK
# =============================================================================

# Aplica un impulso de knockback si la fuerza supera la resistencia del enemigo.
func apply_knockback(dir: Vector2, force: float = 500.0, duration: float = 0.2) -> void:
	if knockback_resistance < force:
		knockback = dir * (force - knockback_resistance)
		knockback_time = duration


# =============================================================================
# DAÑO Y MUERTE
# =============================================================================

# Descuenta salud, aplica el tinte de daño y gestiona la muerte.
# Usa damage_ticks para que el tinte no desaparezca si varios daños llegan a la vez.
func take_damage(damage: float) -> void:
	damage_ticks += 1
	visuals.modulate = damage_color
	health -= damage
	await get_tree().create_timer(0.2).timeout
	damage_ticks -= 1
	print(health)
	# Solo restaura el color blanco cuando ya no queda ningún tick de daño pendiente
	if damage_ticks <= 0:
		visuals.modulate = Color(1, 1, 1)
	if health <= 0:
		die()
	else:
		_on_damage()

# Destruye el nodo del enemigo al morir.
func die() -> void:
	queue_free()


# =============================================================================
# DAÑO POR CONTACTO Y TRAMPAS
# =============================================================================

# Callback del área de detección: aplica daño al jugador por contacto o recibe daño de trampas.
func _on_area_2d_body_entered(body: Node) -> void:
	if _frozen:
		return
	if body.is_in_group("player"):
		do_damage(body)
	if body.is_in_group("trap"):
		if body.has_method("do_damage"):
			body.do_damage($Detector)

# Aplica knockback y daño de contacto al jugador si puede recibir daño en este momento.
func do_damage(body: Node) -> void:
	var knockback_direction = (body.global_position - global_position).normalized()
	if body.is_in_group("player"):
		if is_player_damagable(body):
			body.apply_knockback(knockback_direction, knockback_force)
			body.take_damage(contact_damage)

# Conecta la señal del detector de colisiones al callback de área.
func _get_detector() -> void:
	$Detector.body_entered.connect(_on_area_2d_body_entered)

# Devuelve el daño de contacto del enemigo.
func get_damage() -> float:
	return contact_damage

# Delega la comprobación de invulnerabilidad al propio jugador.
func is_player_damagable(body: Character) -> bool:
	return body.is_player_damagable()


# =============================================================================
# EFECTOS DE ESTADO
# =============================================================================

# Añade un efecto de estado (veneno, ralentización…) al controlador de efectos.
func apply_effect(effect: StatusEffect) -> void:
	if effects != null:
		effects.add_effect(effect)

# Devuelve la velocidad efectiva del enemigo aplicando el multiplicador de efectos activos.
func get_effective_speed() -> float:
	var mult := 1.0
	if effects != null:
		mult = effects.get_speed_multiplier()
	return speed * mult


# =============================================================================
# CAMBIO DE COLOR ESPECIAL
# =============================================================================

# Aplica un tinte de color al enemigo durante color_time segundos con cooldown posterior.
# El flag can_change_color evita que se solapen múltiples llamadas.
func change_color(new_color: Color) -> void:
	if can_change_color:
		visuals.modulate = new_color
		can_change_color = false
		await get_tree().create_timer(color_time).timeout
		visuals.modulate = Color(1, 1, 1)
		await get_tree().create_timer(color_time_cooldown).timeout
		can_change_color = true


# =============================================================================
# AUDIO
# =============================================================================

# Crea y configura el AudioStreamPlayer2D del enemigo en el bus SFX.
func setup_audio() -> void:
	sfx_enemy = AudioStreamPlayer2D.new()
	sfx_enemy.name = "SFXEnemy"
	sfx_enemy.bus = "SFX"
	sfx_enemy.max_polyphony = 16
	add_child(sfx_enemy)

# Reproduce un sonido del diccionario sounds con volumen y pitch opcionales.
func play_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	sfx_enemy.stream = sounds[sound_name]
	sfx_enemy.volume_db = volume_db
	sfx_enemy.pitch_scale = pitch
	sfx_enemy.play()


# =============================================================================
# MÉTODO ABSTRACTO
# =============================================================================

# Cada enemigo concreto implementa su reacción específica al recibir daño sin morir.
@abstract func _on_damage() -> void

@abstract
extends Node2D
class_name Weapon

# =============================================================================
# REFERENCIAS A NODOS
# =============================================================================

# Referencia al árbol de escena (se usa para obtener nodos globales si es necesario)
@onready var player = get_tree()
# Timer que controla la cadencia de disparo del arma
@onready var cooldown_timer = $ShootCooldown
# Reproductor de audio del arma (se crea dinámicamente en setup_audio)
@onready var audio_player: AudioStreamPlayer2D


# =============================================================================
# PARÁMETROS EXPORTADOS
# =============================================================================

# Daño base del arma
@export var damage: float = 1.5
# Daño adicional que se suma al base (puede venir de ítems o modificadores)
@export var extra_damage: float = 0.0
# Tiempo de vida extra añadido a los proyectiles de esta arma
@export var extra_lifetime: float = 0.0
# Fuerza de knockback aplicada al objetivo al impactar
@export var knockback_force: float = 50.0
# Fuerza de retroceso aplicada al propio jugador al disparar
@export var self_knockback_force: float = 50.0


# =============================================================================
# VARIABLES DE ESTADO
# =============================================================================

# Indica si el arma está en medio de un ataque (bloquea la órbita en CharacterCombat)
var is_attacking: bool = false
# Flag de flip horizontal del arma (gestionado externamente por CharacterCombat)
var flip: bool = true
# ID numérico del arma dentro del sistema de combat
var id: int = 0
# Tiempo de vida de los proyectiles generados por esta arma
var lifetime: float = 0.0
# Velocidad de los proyectiles generados por esta arma
var speed: float = 0.0
# Diccionario de sonidos precargados indexados por nombre
var sounds: Dictionary = {}


# =============================================================================
# KNOCKBACK AL JUGADOR
# =============================================================================

# Aplica retroceso al jugador en dirección opuesta al arma al disparar.
func give_knocback():
	var body = get_parent().get_parent()
	var knockback_direction = (body.global_position - global_position).normalized()
	get_parent().get_parent().apply_knockback(knockback_direction, self_knockback_force)


# =============================================================================
# DESTRUCCIÓN DEL ARMA
# =============================================================================

# Elimina el arma del ciclo de combat del jugador (p.ej. al quedar sin munición).
func destroy_weapon():
	var body = get_parent().get_parent()
	body.combat.remove_weapon(id)


# =============================================================================
# AUDIO
# =============================================================================

# Crea y configura el AudioStreamPlayer2D del arma en el bus SFX.
func setup_audio():
	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "SFXWeapon"
	audio_player.bus = "SFX"
	audio_player.max_polyphony = 16
	add_child(audio_player)

# Reproduce un sonido del diccionario sounds con volumen y pitch opcionales.
# Emite un warning si el nombre no existe en el diccionario.
func play_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0):
	if not sounds.has(sound_name):
		push_warning("Sonido '" + sound_name + "' no encontrado.")
		return

	audio_player.stream = sounds[sound_name]
	audio_player.volume_db = volume_db
	audio_player.pitch_scale = pitch
	audio_player.play()

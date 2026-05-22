extends Node

# =============================================================================
# VARIABLES DE ESTADO DE LA PARTIDA
# =============================================================================

# Piso actual de la run (empieza en 1 y sube con cada next_floor)
var current_floor: int = 1
# Escala de tiempo global del motor (1.0 = velocidad normal)
var game_time_scale: float = 1.0
# Generador de números aleatorios compartido con el resto del juego
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
# Seed usada para la generación procedural; -1 significa "generar automáticamente"
@export var seed_value: int = -1
# Lista de IDs de bosses ya derrotados en esta run (evita repeticiones)
var used_bosses: Array[String] = []

# Número de piso que se considera el último (activa el boss final)
@export var last_floor: int = 3
# ID del boss final reservado para el último piso
@export var final_boss_id: String = "buffed_alien"

# Flag que indica que el jugador quiere continuar una partida guardada
var continue_requested: bool = false


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	Engine.time_scale = game_time_scale
	# Resetea el estado al morir para dejar el GameManager limpio
	Signals.show_death_menu.connect(_on_death_menu)
	generate_seed()


# =============================================================================
# RESET
# =============================================================================

# Devuelve todos los valores al estado inicial de una run nueva y genera una seed fresca.
func reset():
	current_floor = 1
	game_time_scale = 1.0
	seed_value = -1
	used_bosses.clear()
	continue_requested = false
	generate_seed()


# =============================================================================
# SEED Y ALEATORIEDAD
# =============================================================================

# Genera (o reutiliza) la seed de la run y la asigna al RNG compartido.
# Si seed_value es -1 usa el tiempo Unix como seed aleatoria.
func generate_seed() -> int:
	if seed_value == -1:
		seed_value = int(Time.get_unix_time_from_system())
	rng.seed = seed_value
	return seed_value


# =============================================================================
# GESTIÓN DE PISOS
# =============================================================================

# Avanza al siguiente piso.
func next_floor() -> void:
	current_floor += 1

# Devuelve el número del piso actual.
func get_current_floor() -> int:
	return current_floor

# Devuelve true si el piso actual es el último (se debe usar el boss final).
func is_last_floor() -> bool:
	return current_floor >= last_floor

# Calcula la vida real de un enemigo según el piso actual.
# Se recomienda pasar la vida base del enemigo y el piso (por defecto el actual).
# Puedes ajustar el factor para que sea más suave o más agresivo.
func calculate_enemy_health(base_health: float, floor: int = current_floor) -> float:
	var health_multiplier := 1.0
	match floor:
		1:
			health_multiplier = 1.0
		2:
			health_multiplier = 1.5 
		3:
			health_multiplier = 2.25
		_:
			health_multiplier = 1.75 + (0.25 * (floor - 3))
	return base_health * health_multiplier

# =============================================================================
# GESTIÓN DE BOSSES USADOS
# =============================================================================

# Comprueba si un boss ya fue usado en esta run.
func is_boss_used(boss_id: String) -> bool:
	return boss_id in used_bosses

# Registra un boss como usado para no repetirlo en pisos posteriores.
func mark_boss_used(boss_id: String) -> void:
	if boss_id not in used_bosses:
		used_bosses.append(boss_id)


# =============================================================================
# CALLBACKS DE SEÑALES
# =============================================================================

# Al morir, resetea el estado completo de la partida.
func _on_death_menu():
	reset()

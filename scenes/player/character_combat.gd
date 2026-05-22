extends Node
class_name CharacterCombat

# =============================================================================
# VARIABLES DE ESTADO Y REFERENCIAS
# =============================================================================

# Referencia a las stats del personaje (para pasar daño y lifetime al disparar)
var stats: CharacterStats = null
# Nodo del arma actualmente equipada
var current_weapon: Node2D = null
# Índice dentro de weapon_order que apunta al arma activa
@export var current_weapon_index: int = 0
# Nodo padre donde se instancian y adjuntan las armas
var weapon_holder: Node2D = null


# =============================================================================
# PARÁMETROS DE ÓRBITA DEL ARMA
# =============================================================================

# Radio en píxeles al que el arma orbita alrededor del personaje
@export var orbit_radius: float = 13
# Radio de órbita adicional (reservado para efectos o ítems)
@export var weapon_orbit_radius: float = 0
# Factor de suavizado del movimiento de órbita (mayor = más rápido)
@export var orbit_smoothness: float = 10.0


# =============================================================================
# ESCENAS DE ARMAS PRECARGADAS
# =============================================================================

#region Weapons Scenes
var arm_scene: PackedScene = preload("res://scenes/weapons/arm_weapon.tscn")
var pistol_scene: PackedScene = preload("res://scenes/weapons/pistol_weapon.tscn")
var nail_scene: PackedScene = preload("res://scenes/weapons/nail_weapon.tscn")
var blue_marker_scene: PackedScene = preload("res://scenes/weapons/blue_marker_weapon.tscn")
var continous_laser_scene: PackedScene = preload("res://scenes/weapons/continous_laser_weapon.tscn")
var exploding_kittens_scene: PackedScene = preload("res://scenes/weapons/exploding_kittens_weapon.tscn")
var shotgun_inter_mark_hat_scene: PackedScene = preload("res://scenes/weapons/shotgun_inter_mark_weapon.tscn")
var black_knife_scene: PackedScene = preload("res://scenes/weapons/black_knife_weapon.tscn")
var shuriken_scene: PackedScene = preload("res://scenes/weapons/shuriken_weapon.tscn")
var eye_of_the_witch: PackedScene = preload("res://scenes/weapons/eye_of_the_witch_weapon.tscn")
#endregion

# Diccionario que mapea ID numérico → PackedScene (se rellena en fill_weapon_scenes)
var weapon_scenes: Dictionary = {}
# Diccionario que cachea instancias ya creadas: ID → Node2D (evita reinstanciar al cambiar arma)
@export var weapon_instances: Dictionary = {}
# Lista ordenada de IDs de armas disponibles para el jugador; define el ciclo de cambio
@export var weapon_order: Array = [1]


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready():
	fill_weapon_scenes()

# Rellena el diccionario weapon_scenes relacionando cada ID con su PackedScene.
func fill_weapon_scenes():
	weapon_scenes = {
		1: arm_scene,
		2: pistol_scene,
		3: blue_marker_scene,
		4: nail_scene,
		5: continous_laser_scene,
		6: exploding_kittens_scene,
		7: shotgun_inter_mark_hat_scene,
		8: black_knife_scene,
		9: shuriken_scene,
		10: eye_of_the_witch,
	}

# Asigna el weapon_holder y las stats, y equipa el arma inicial según weapon_order.
# Si no hay orden definido ni stats, equipa un arma aleatoria.
func init(holder: Node2D, character_stats: CharacterStats):
	weapon_holder = holder
	stats = character_stats

	if weapon_scenes.is_empty():
		_ready()

	if weapon_order.is_empty() and stats == null:
		random_weapon()
	else:
		var initial_id = weapon_order[current_weapon_index]
		equip_weapon(initial_id)


# =============================================================================
# ACTUALIZACIÓN POR FRAME (ÓRBITA, FLIP Y INPUT)
# =============================================================================

# Llamado cada frame desde el personaje: mueve el arma en órbita hacia el ratón,
# gestiona el flip horizontal y procesa los inputs de disparo y cambio de arma.
func update(delta: float, character):
	if not current_weapon:
		return

	var mouse_pos = character.get_global_mouse_position()
	var angle_to_mouse = (mouse_pos - character.global_position).angle()
	var target_offset = Vector2.RIGHT.rotated(angle_to_mouse) * orbit_radius

	# Solo orbita suavemente si el arma no está en medio de un ataque
	if not current_weapon.is_attacking:
		current_weapon.position = current_weapon.position.lerp(target_offset, delta * orbit_smoothness)
		current_weapon.rotation = lerp_angle(current_weapon.rotation, angle_to_mouse, delta * orbit_smoothness)

	# Voltea el arma verticalmente cuando el ratón está a la izquierda del personaje
	if abs(angle_to_mouse) > PI/2 and not current_weapon.is_attacking:
		current_weapon.scale.y = -1
	else:
		current_weapon.scale.y = 1

	if Input.is_action_pressed("shoot"):
		shoot()

	# Al soltar el disparo, notifica al arma para que detenga efectos continuos
	if Input.is_action_just_released("shoot"):
		if current_weapon and current_weapon.has_method("stop_shooting"):
			current_weapon.stop_shooting()

	# Cambio de arma: detiene el disparo actual antes de rotar al siguiente
	if Input.is_action_just_pressed("next_weapon"):
		if current_weapon and current_weapon.has_method("stop_shooting"):
			current_weapon.stop_shooting()
		next_weapon()

	if Input.is_action_just_pressed("tests"):
		Input.warp_mouse(Vector2(500, 500))


# =============================================================================
# DISPARO
# =============================================================================

# Llama al método de disparo del arma activa pasándole el daño y lifetime calculados.
# Soporta armas con disparo continuo (start_shooting) y disparo puntual (shoot).
func shoot():
	if current_weapon.has_method("start_shooting"):
		current_weapon.start_shooting(stats.get_damage(), stats.get_lifetime())
	elif current_weapon.has_method("shoot"):
		current_weapon.shoot(stats.get_damage(), stats.get_lifetime())


# =============================================================================
# GESTIÓN DE ARMAS
# =============================================================================

# Equipa el arma con el ID indicado: oculta la anterior, instancia la nueva si no existe
# en caché, y la hace visible y activa.
func equip_weapon(id: int):
	if not weapon_scenes.has(id):
		return

	if current_weapon:
		current_weapon.visible = false
		current_weapon.set_process(false)

	# Instancia el arma solo la primera vez; las siguientes la reutiliza del caché
	if not weapon_instances.has(id):
		var scene: PackedScene = weapon_scenes[id]
		var instance = scene.instantiate()
		weapon_holder.call_deferred("add_child", instance)
		weapon_instances[id] = instance

	current_weapon = weapon_instances[id]
	current_weapon.visible = true
	current_weapon.set_process(true)
	Signals.weapon_changed.emit()

# Elimina un arma del ciclo de weapon_order.
# Si era la activa, equipa la última arma del orden restante.
func remove_weapon(id: int):
	var current_id = weapon_order[current_weapon_index]
	if current_id == id:
		weapon_order.erase(id)
		equip_last_weapon()
	else:
		weapon_order.erase(id)

# Avanza al siguiente arma en weapon_order de forma circular.
func next_weapon():
	current_weapon_index += 1
	if current_weapon_index >= weapon_order.size():
		current_weapon_index = 0

	var next_id = weapon_order[current_weapon_index]
	equip_weapon(next_id)

# Añade un arma al ciclo por ID (si no estaba ya) y la equipa inmediatamente.
func add_weapon(id: int):
	if not weapon_scenes.has(id):
		return

	if id not in weapon_order:
		weapon_order.append(id)

	equip_last_weapon()

# Equipa el último arma del array weapon_order (la más recientemente añadida).
func equip_last_weapon():
	var last_id: int = 0

	for item_id in weapon_order:
		last_id = item_id

	equip_weapon(last_id)

# Elige y equipa un arma aleatoria del pool disponible (usado cuando no hay orden definido).
func random_weapon():
	var rng := RandomNumberGenerator.new()
	var keys := weapon_scenes.keys()
	var chosen_weapon: int = int(keys[rng.randi_range(0, keys.size() - 1)])
	weapon_order.append(chosen_weapon)
	current_weapon_index = weapon_order.size() - 1
	equip_weapon(chosen_weapon)

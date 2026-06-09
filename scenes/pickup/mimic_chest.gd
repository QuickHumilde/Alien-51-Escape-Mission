extends Pickup

@export var activable: bool = true

@onready var coin_scene: PackedScene = preload("res://scenes/pickup/coin.tscn")
@onready var health_scene: PackedScene = preload("res://scenes/pickup/health.tscn")
@onready var shield_scene: PackedScene = preload("res://scenes/pickup/shield_bowl.tscn")
@onready var enemy1_scene: PackedScene = preload("res://scenes/enemies/stickman/stickman_enemy.tscn")
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D

# Porcentajes para el pickup aleatorio (coin, health, shield, enemy)
@export var coin_percentage: float = 25.0
@export var health_percentage: float = 15.0
@export var shield_percentage: float = 50.0
@export var enemy1_percentage: float = 10.0

# Rango de monedas extra que siempre se generan (1-2)
@export var min_extra_coins: int = 1
@export var max_extra_coins: int = 2

# Flag para evitar abrir el cofre múltiples veces
var spawned: bool = false

# =============================================================================
# APERTURA DEL COFRE
# =============================================================================

# Se llama cuando el jugador recoge el cofre.
# Genera monedas extra y un pickup aleatorio.
func open_chest():
	if spawned:
		return

	# Obtén la referencia al nodo de pickups (contenedor donde se añaden los items)
	var pickups := _get_pickups_node()
	if pickups == null:
		return

	# Reproduce la animación de apertura
	sprite.play("open")

	# Genera de 1-2 monedas extra
	_spawn_extra_coins(pickups)

	# Genera un pickup aleatorio (según los porcentajes)
	_spawn_random_pickup(pickups)

	# Reproduce el sonido de apertura
	AudioManager.play_sfx("chest_opened", -2.0)
	spawned = true


# =============================================================================
# GENERACIÓN DE MONEDAS EXTRA
# =============================================================================

# Genera un número aleatorio de monedas (1-2) y las coloca alrededor del cofre.
func _spawn_extra_coins(pickups: Node) -> void:
	# Número aleatorio entre min_extra_coins y max_extra_coins (inclusive)
	var coin_count := randi_range(min_extra_coins, max_extra_coins)

	for i in range(coin_count):
		# Instancia una moneda
		var coin: Node = coin_scene.instantiate()
		pickups.add_child(coin)

		# Coloca la moneda en la posición del cofre
		if coin is Node2D:
			(coin as Node2D).global_position = global_position

		# Aplica un pequeño offset aleatorio para que no se solapen todas en el mismo punto
		if coin is Node2D:
			var offset := Vector2(
				randf_range(-20.0, 20.0),  # desplazamiento aleatorio en X
				randf_range(-20.0, 20.0)   # desplazamiento aleatorio en Y
			)
			(coin as Node2D).global_position += offset


# =============================================================================
# GENERACIÓN DE PICKUP ALEATORIO
# =============================================================================

# Selecciona y genera un pickup aleatorio según los porcentajes configurados.
func _spawn_random_pickup(pickups: Node) -> void:
	# Obtén la escena del pickup aleatorio
	var scene: PackedScene = _pick_weighted_scene()
	if scene == null:
		return

	# Instancia el pickup
	var instant: Node = scene.instantiate()
	pickups.add_child(instant)

	# Coloca el pickup en la posición del cofre
	if instant is Node2D:
		(instant as Node2D).global_position = global_position


# =============================================================================
# SELECCIÓN PONDERADA DE ESCENA
# =============================================================================

# Elige una escena al azar según los porcentajes exportados.
# Retorna la PackedScene seleccionada, o null si los porcentajes son inválidos.
func _pick_weighted_scene() -> PackedScene:
	var coin = max(0.0, coin_percentage)
	var health = max(0.0, health_percentage)
	var shield = max(0.0, shield_percentage)
	var enemy1 = max(0.0, enemy1_percentage)

	var total = coin + health + shield + enemy1
	if total <= 0.0:
		return null

	# Genera un número aleatorio entre 0 y el total
	var random_number = randf() * total

	# Determina cuál pickup se genera según el rango
	if random_number < coin:
		return coin_scene
	elif random_number < coin + health:
		return health_scene
	elif random_number < coin + health + shield:
		return shield_scene
	else:
		return enemy1_scene


# =============================================================================
# OBTENCIÓN DEL NODO DE PICKUPS
# =============================================================================

# Busca el nodo "Pickups" subiendo en el árbol desde la posición actual.
# Si no lo encuentra, retorna el padre directo.
func _get_pickups_node() -> Node:
	var room := get_parent()

	# Sube en el árbol hasta encontrar un nodo con hijo "Pickups"
	while room != null and room.get_node_or_null("Pickups") == null and room.get_parent() != null:
		room = room.get_parent()

	# Si encontró "Pickups", devuélvelo; si no, devuelve el padre directo
	var pickups := room.get_node_or_null("Pickups") if room != null else null
	return pickups if pickups != null else get_parent()


# =============================================================================
# CALLBACKS
# =============================================================================

# Comprueba si el cofre puede ser abierto.
func is_activable() -> bool:
	return activable


# Se ejecuta cuando el jugador recoge el cofre.
func _on_pick_up(_player: Character):
	if activable:
		call_deferred("open_chest")

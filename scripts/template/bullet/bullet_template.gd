@abstract
extends Area2D
class_name Bullet

# =============================================================================
# VARIABLES DE ESTADO
# =============================================================================

# Velocidad de desplazamiento en píxeles por segundo
var speed: float = 0.0
# Daño que aplica al impactar
var damage: float = 0.0
# Fuerza de empuje aplicada al objetivo al impactar
var knockback_force: float = 0.0
# Tiempo de vida máximo en segundos antes de destruirse automáticamente
var lifetime: float = 5.0
# Dirección de movimiento normalizada
var bullet_direction = Vector2.RIGHT
# Tiempo de vida restante (cuenta regresiva desde lifetime)
var time_left: float
# Lista de modificadores activos (ej: "piercing", "spectral")
var modifiers: Array = []
# Indica quién disparó la bala ("player", "enemy" o "-") para evitar daño propio
var bullet_owner: String = "-"
# Velocidad de rotación visual en grados por segundo (0 = sin rotación)
var speed_rotation: float = 0.0
# Registro de enemigos ya golpeados en este disparo (evita aplicar daño múltiple veces)
var hit_enemies: Dictionary = {}


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready():
	# Conecta las señales de colisión tanto con cuerpos como con áreas
	self.body_entered.connect(_on_hitbox_enter)
	self.area_entered.connect(_on_hitbox_enter)
	time_left = lifetime

# Configura todos los parámetros de la bala en el momento del spawn.
# extras puede contener "modifiers" para añadir efectos especiales.
func init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_bullet_owner, extras: Dictionary = {}) -> void:
	self.global_position = new_position
	self.bullet_direction = new_forward
	self.damage = new_damage
	self.knockback_force = new_knockback_force
	self.lifetime = new_lifetime
	self.speed = new_speed
	self.bullet_owner = new_bullet_owner
	if extras.has("modifiers"):
		self.modifiers = extras.modifiers


# =============================================================================
# MOVIMIENTO Y VIDA ÚTIL
# =============================================================================

# Mueve la bala en su dirección cada frame, gestiona su rotación visual,
# cuenta el tiempo de vida y comprueba solapamientos activos.
func _process(delta: float):
	if get_tree().paused:
		return
	global_position += bullet_direction * speed * delta
	rotation_degrees += speed_rotation * delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
	# Comprueba colisiones con áreas y cuerpos solapados en cada frame
	for area in get_overlapping_areas():
		_on_hitbox_enter(area)
	for body in get_overlapping_bodies():
		_on_hitbox_enter(body)


# =============================================================================
# DETECCIÓN DE COLISIONES
# =============================================================================

# Punto central de resolución de colisiones: distribuye la lógica según el grupo del objetivo.
func _on_hitbox_enter(area):
	if area.is_in_group("obstacle"):
		_against_obstacle(area)

	if area.is_in_group("wall"):
		_against_wall()

	# Solo daña enemigos si la bala no fue disparada por un enemigo
	if area.is_in_group("enemy") and bullet_owner != "enemy":
		var enemy_node = area.get_parent()
		# Evita aplicar daño dos veces al mismo enemigo en el mismo disparo
		if hit_enemies.has(enemy_node):
			return
		hit_enemies[enemy_node] = true
		# Limpia el registro cuando el enemigo abandona el árbol
		if is_instance_valid(enemy_node):
			if not enemy_node.is_connected("tree_exited", Callable(self, "_on_enemy_tree_exited")):
				enemy_node.connect("tree_exited", Callable(self, "_on_enemy_tree_exited").bind(enemy_node))
		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)
		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)
		_against_enemy(area)

	# Solo daña al jugador si la bala no fue disparada por el jugador
	if area.is_in_group("player") and bullet_owner != "player":
		var player_node = area.get_parent()
		if player_node.has_method("apply_knockback"):
			var knockback_direction = (player_node.global_position - global_position).normalized()
			player_node.apply_knockback(knockback_direction, knockback_force)
		if player_node.has_method("take_damage"):
			player_node.take_damage(damage)
		_against_enemy(area)

# Elimina un enemigo del registro hit_enemies cuando sale del árbol de escena.
func _on_enemy_tree_exited(enemy_node):
	if hit_enemies.has(enemy_node):
		hit_enemies.erase(enemy_node)


# =============================================================================
# REACCIONES A IMPACTO
# =============================================================================

# Al golpear un obstáculo: notifica al obstáculo y destruye la bala salvo que sea "spectral".
func _against_obstacle(area):
	if area.has_method("receive_hit"):
		area.receive_hit()
	if not modifiers.has("spectral"):
		destroy_bullet()

# Al golpear una pared: destruye la bala siempre.
func _against_wall():
	destroy_bullet()

# Al golpear un enemigo o jugador: destruye la bala salvo que tenga el modificador "piercing".
func _against_enemy(_area):
	if not modifiers.has("piercing"):
		destroy_bullet()


# =============================================================================
# UTILIDADES
# =============================================================================

# Cambia la dirección de vuelo de la bala en tiempo de ejecución.
# Opcionalmente actualiza el propietario (útil para balas redirigidas por ítems).
func change_direction(new_direction: Vector2, new_owner = ""):
	if new_owner != "":
		bullet_owner = new_owner
	bullet_direction = new_direction

# Destruye la bala liberando su nodo del árbol.
func destroy_bullet():
	queue_free()

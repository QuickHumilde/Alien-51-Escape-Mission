extends Area2D
class_name DeodorantScene

# =============================================================================
# PARÁMETROS EXPORTADOS
# =============================================================================

# Daño aplicado por segundo a cada enemigo en el área
@export var damage_per_second: float = 0.75
# Fuerza de knockback aplicada por segundo (0 = sin empuje)
@export var knockback_force_per_second: float = 0.0
# Solo daña nodos de este grupo ("enemy" por defecto; "" = cualquiera)
@export var only_damage_group: String = "enemy"
# Activa el dibujo personalizado del área (nube de olor animada)
@export var debug_draw: bool = true
# Paleta de colores que cicla la animación del olor
@export var odor_colors: Array[Color] = [
	Color(0.506, 0.584, 0.0, 0.431),
	Color(0.486, 0.498, 0.024, 0.431),
	Color(0.424, 0.498, 0.286, 0.431)
]
# Grosor del borde del polígono dibujado
@export var debug_width: float = 1.5


# =============================================================================
# REFERENCIAS Y ESTADO
# =============================================================================

@onready var col_shape: CollisionShape2D = $CollisionShape2D

# Lista de nodos actualmente dentro del área (cuerpos y áreas)
var _targets: Array[Node] = []
# Acumulador de tiempo para la animación de la nube
var _anim_time: float = 0.0


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	queue_redraw()


# =============================================================================
# DAÑO POR FRAME
# =============================================================================

# Aplica daño y knockback proporcional al delta a cada enemigo único en el área.
# Limpia del array los nodos que ya no son válidos.
func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

	if _targets.is_empty():
		return

	# Deduplica objetivos: varios hitboxes del mismo enemigo solo cuentan una vez
	var unique_enemies: Dictionary = {}
	for i in range(_targets.size() - 1, -1, -1):
		var t := _targets[i]
		if t == null or not is_instance_valid(t):
			_targets.remove_at(i)
			continue
		var enemy := _get_damageable_owner(t)
		if enemy != null:
			unique_enemies[enemy] = true

	var dmg := damage_per_second * delta
	for enemy in unique_enemies.keys():
		if enemy.has_method("take_damage"):
			enemy.take_damage(dmg)
		if knockback_force_per_second > 0.0 and enemy.has_method("apply_knockback"):
			var dir := ((enemy as Node2D).global_position - global_position).normalized()
			enemy.apply_knockback(dir, knockback_force_per_second * delta)


# =============================================================================
# CALLBACKS DE COLISIÓN
# =============================================================================

func _on_body_entered(body: Node) -> void:
	_try_add_target(body)

func _on_body_exited(body: Node) -> void:
	_targets.erase(body)

func _on_area_entered(area: Area2D) -> void:
	_try_add_target(area)

func _on_area_exited(area: Area2D) -> void:
	_targets.erase(area)

# Añade un nodo al array de objetivos evitando duplicados.
func _try_add_target(n: Node) -> void:
	if n == null:
		return
	if not _targets.has(n):
		_targets.append(n)


# =============================================================================
# DETECCIÓN DEL NODO DAÑABLE
# =============================================================================

# Recorre la jerarquía del nodo hacia arriba buscando el primer ancestro dañable
# del grupo indicado. Devuelve null si encuentra al jugador (para no dañarlo).
func _get_damageable_owner(n: Node) -> Node:
	var cur: Node = n
	while cur != null:
		if cur.is_in_group("player"):
			return null
		if only_damage_group != "" and cur.is_in_group(only_damage_group):
			return cur
		if cur.has_method("take_damage"):
			return cur
		cur = cur.get_parent()
	return null


# =============================================================================
# DIBUJO DE LA NUBE DE OLOR
# =============================================================================

# Dibuja un polígono circular con radio oscilante y color interpolado
# entre los colores de odor_colors para simular una nube de gas animada.
func _draw() -> void:
	if not debug_draw:
		return
	if col_shape == null or col_shape.shape == null:
		return

	var s := col_shape.shape as CircleShape2D
	var offset := col_shape.position
	var num = odor_colors.size()

	# Interpola suavemente entre colores consecutivos de la paleta
	var t = _anim_time * 0.5
	var idx1 = int(floor(t)) % num
	var idx2 = (idx1 + 1) % num
	var weight = t - floor(t)
	var color = odor_colors[idx1].lerp(odor_colors[idx2], weight)

	var base_radius = s.radius
	var points = []
	var detail = 42  # Número de vértices del polígono (más = más suave)

	# Genera los vértices con radio variable usando senos anidados para el efecto orgánico
	for i in detail:
		var ang = (TAU / detail) * i
		var r_osc = base_radius * (1.0 + 0.07 * sin(ang * 3.0 + _anim_time * 1.3 + sin(ang * 2.1 + _anim_time)))
		var point = offset + Vector2.RIGHT.rotated(ang) * r_osc
		points.append(point)

	draw_colored_polygon(points, color)

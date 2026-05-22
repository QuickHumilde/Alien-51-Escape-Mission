extends Bullet
class_name HomingBullet

# =============================================================================
# VARIABLES DE GUIADO
# =============================================================================

# Velocidad de giro en radianes por segundo (cuánto de rápido rota hacia el objetivo)
@export var turn_speed: float = 4.0
# Radio en píxeles dentro del cual la bala puede detectar objetivos
@export var homing_radius: float = 70.0
# Grupo de nodos que la bala perseguirá ("enemy" por defecto)
@export var target_group: String = "enemy"

# Área circular que detecta posibles objetivos dentro del radio de guiado
@onready var homing_area: Area2D = $HomingArea
@onready var homing_area_collision: CollisionShape2D = $HomingArea/CollisionShape2D

# Referencia al nodo objetivo actual (null si no hay ninguno en rango)
var target: Node2D = null


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

# Sobreescribe el init de Bullet para forzar el modificador "spectral"
# (la bala teledirigida atraviesa obstáculos) y aplicar parámetros extra de guiado.
func init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_bullet_owner, extras: Dictionary = {}) -> void:
	extras = {
		"modifiers": ["spectral"]
	}
	super.init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_bullet_owner, extras)
	if extras.has("turn_speed"):
		turn_speed = extras.turn_speed
	if extras.has("homing_radius"):
		homing_radius = extras.homing_radius
		homing_area_collision.shape.radius = homing_radius

# Llama al _ready de Bullet, conecta el área de guiado y busca el objetivo más cercano
# entre los cuerpos que ya estén solapando en el momento del spawn.
func _ready() -> void:
	super._ready()
	homing_area.body_entered.connect(_on_homing_area_enter)

	# Selecciona el objetivo más cercano de los que ya están dentro del área
	var bodies = homing_area.get_overlapping_bodies()
	var best_target: Node2D = null
	var first_time: bool = true

	for body in bodies:
		if target == null and body.is_in_group(target_group):
			if first_time:
				best_target = body
			else:
				var distance = global_position.distance_to(body.global_position)
				if distance < global_position.distance_to(best_target.global_position):
					best_target = body
	if best_target != null:
		target = best_target


# =============================================================================
# MOVIMIENTO CON GUIADO
# =============================================================================

# Sobreescribe el _process de Bullet para añadir la lógica de seguimiento:
# rota la dirección de vuelo suavemente hacia el objetivo usando slerp,
# y limpia el objetivo si ya no está en rango o ha dejado de ser válido.
func _process(delta: float):
	if get_tree().paused:
		return

	# Invalida el objetivo si ha muerto o salido del área de guiado
	if target != null:
		if not is_instance_valid(target) or not homing_area.get_overlapping_bodies().has(target):
			target = null

	# Gira la dirección de vuelo hacia el objetivo de forma gradual
	if target != null:
		var desired := (target.global_position - global_position).normalized()
		bullet_direction = bullet_direction.slerp(desired, clamp(turn_speed * delta, 0.0, 1.0)).normalized()

	# El resto del movimiento es idéntico al de Bullet base
	global_position += bullet_direction * speed * delta
	rotation_degrees += speed_rotation * delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
	for area in get_overlapping_areas():
		_on_hitbox_enter(area)
	for body in get_overlapping_bodies():
		_on_hitbox_enter(body)


# =============================================================================
# DETECCIÓN DE NUEVO OBJETIVO
# =============================================================================

# Asigna el primer cuerpo del grupo objetivo que entre en el área de guiado.
func _on_homing_area_enter(body):
	if target == null and body.is_in_group(target_group):
		target = body

extends Node2D
class_name Door

signal entered(dir: String)

# =============================================================================
# VARIABLES Y REFERENCIAS
# =============================================================================

# Dirección que representa esta puerta ("up", "down", "left", "right")
@export var dir: String = "up"

# Área que detecta al jugador para emitir la señal de entrada
@onready var trigger: Area2D = $Trigger
@onready var trigger_shape: CollisionShape2D = $Trigger/CollisionShape2D
# AnimationPlayer para las animaciones de apertura y cierre
@onready var anim: AnimationPlayer = $AnimationPlayer

# Visual de la pared (visible cuando la puerta está deshabilitada)
@onready var wall_visual: CanvasItem = get_node_or_null("Wall/WallVisual") as CanvasItem
# Visual de la puerta (visible cuando la puerta está habilitada)
@onready var door_visual: CanvasItem = get_node_or_null("DoorVisual") as CanvasItem
# Colisión bloqueadora de la puerta (desactivada cuando está abierta)
@onready var blocker_door_shape: CollisionShape2D = get_node_or_null("BlockerDoor/CollisionShape2D") as CollisionShape2D
# Colisión bloqueadora de la pared (activa cuando la puerta está deshabilitada)
@onready var blocker_wall_shape: CollisionShape2D = get_node_or_null("Wall/BlockerWall/CollisionShape2D") as CollisionShape2D

# Flag que indica si la puerta existe en el mapa (conecta dos salas)
var _enabled: bool = true
# Flag que indica si la puerta está abierta (sin bloqueo físico ni visual)
var _open: bool = true


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	if trigger != null:
		trigger.body_entered.connect(_on_body_entered)
	# Ajusta los bloqueadores según la dirección para compensar offsets visuales
	_adjust_trigger_hitbox()


# =============================================================================
# HABILITACIÓN DE LA PUERTA
# =============================================================================

# Activa o desactiva la puerta según si el mapa tiene conexión en esa dirección.
# Cuando está deshabilitada se muestra la pared y se desactivan trigger y bloqueador de puerta.
func set_enabled(v: bool) -> void:
	_enabled = v

	# Muestra la pared si no hay puerta, muestra la puerta si sí la hay
	if wall_visual != null:
		wall_visual.visible = not v
	if door_visual != null:
		door_visual.visible = v

	# Activa o desactiva el área de detección del jugador
	if trigger != null:
		trigger.set_deferred("monitoring", v)
		trigger.set_deferred("monitorable", v)
	if trigger_shape != null:
		trigger_shape.set_deferred("disabled", not v)

	# El bloqueador de pared solo actúa cuando no hay puerta
	if blocker_wall_shape != null:
		blocker_wall_shape.set_deferred("disabled", v)

	if v:
		# Si se habilita, aplica el estado de apertura actual
		set_open(_open)
	else:
		# Si se deshabilita, elimina el bloqueador de puerta (la pared ya bloquea)
		if blocker_door_shape != null:
			blocker_door_shape.set_deferred("disabled", true)


# =============================================================================
# APERTURA Y CIERRE
# =============================================================================

# Abre o cierra la puerta: gestiona el bloqueador físico y la animación.
# Solo actúa si la puerta está habilitada y el estado cambia realmente.
func set_open(v: bool) -> void:
	if _open == v:
		return
	_open = v
	if not _enabled:
		return

	# El bloqueador de puerta se desactiva al abrir y se activa al cerrar
	if blocker_door_shape != null:
		blocker_door_shape.set_deferred("disabled", v)

	if anim != null:
		anim.play("open" if v else "close")


# =============================================================================
# DETECCIÓN DEL JUGADOR
# =============================================================================

# Emite la señal "entered" con la dirección cuando el jugador cruza la puerta.
# Solo actúa si la puerta está habilitada y abierta.
func _on_body_entered(body: Node) -> void:
	if not _enabled or not _open:
		return
	if body != null and body.is_in_group("player"):
		emit_signal("entered", dir)


# =============================================================================
# AJUSTE DE HITBOXES POR DIRECCIÓN
# =============================================================================

# Corrige la posición de los bloqueadores según la dirección de la puerta
# para compensar asimetrías visuales del tileset en puertas verticales.
func _adjust_trigger_hitbox() -> void:
	if trigger_shape == null:
		return
	trigger_shape.position = Vector2.ZERO

	match dir:
		"up", "Up":
			blocker_door_shape.position.y -= 4
			blocker_wall_shape.position.y -= 4
		"down", "Down":
			blocker_door_shape.position.y += 2
			blocker_wall_shape.position.y += 2

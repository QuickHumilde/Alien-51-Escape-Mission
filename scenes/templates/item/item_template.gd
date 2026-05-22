@abstract
extends RigidBody2D
class_name Item

# =============================================================================
# VARIABLES Y REFERENCIAS
# =============================================================================

# Colisión del área de recogida (el jugador debe solapar con ella para recoger el ítem)
@onready var hitbox: CollisionShape2D = $Detector/CollisionShape2D

# Clave de localización para el nombre del ítem (se traduce vía TranslationServer)
@export var name_key: String
# Clave de localización para la descripción del ítem
@export var desc_key: String
# Precio en tienda
@export var price: int = 10

# ID numérico único del ítem (asignado por ItemManager; -1 = no inicializado)
var id: int = -1
# Ruta de la textura del ítem usada en la UI de información
var item_texture: String


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready():
	_initiate_detectors()
	_initiate_animations()


# =============================================================================
# RECOGIDA DEL ÍTEM
# =============================================================================

# Callback del área de recogida: aplica los cambios al jugador si entra en contacto.
func _on_hitbox_enter(_body):
	if _body.is_in_group("player"):
		give_changes(_body)

# Método abstracto que cada ítem concreto debe implementar para aplicar sus efectos al jugador.
@abstract func give_changes(body: Character)

# Devuelve el ID numérico del ítem.
func get_id():
	return id

# Emite la señal de recogida y destruye el nodo del ítem en el próximo frame.
func destroy_on_pickup():
	Signals.item_picked.emit(get_id())
	call_deferred("queue_free")


# =============================================================================
# INFORMACIÓN EN PANTALLA
# =============================================================================

# Callback del área de descripción: muestra la información cuando el jugador se acerca.
func _on_hitbox_enter_description(body):
	if body.is_in_group("player"):
		show_information()

# Callback del área de descripción: oculta la información cuando el jugador se aleja.
func _on_hitbox_exit_description(body):
	if body.is_in_group("player"):
		hide_information()

# Devuelve la clave de nombre localizada.
func get_item_name() -> String:
	return (name_key)

# Devuelve la clave de descripción localizada.
func get_description() -> String:
	return (desc_key)

# Devuelve el precio del ítem.
func get_price() -> int:
	return price

# Emite la señal global para que el HUD muestre el nombre, descripción e icono del ítem.
func show_information():
	Signals.show_item_information.emit(get_item_name(), get_description(), item_texture)

# Emite la señal global para que el HUD oculte la información del ítem.
func hide_information():
	Signals.hide_item_information.emit()


# =============================================================================
# GESTIÓN DEL HITBOX
# =============================================================================

# Activa el hitbox de recogida (diferido para evitar problemas de física).
func enable_hitbox():
	hitbox.set_deferred("disabled", false)

# Desactiva el hitbox de recogida (diferido para evitar problemas de física).
func disable_hitbox():
	hitbox.set_deferred("disabled", true)

# Desactiva el hitbox durante un tiempo determinado y luego lo reactiva.
# Útil para evitar que un ítem soltado se recoja inmediatamente.
func disable_pickup(time: float):
	disable_hitbox()
	await get_tree().create_timer(time).timeout
	enable_hitbox()


# =============================================================================
# CONFIGURACIÓN DE DETECTORES Y ANIMACIONES
# =============================================================================

# Conecta las señales de las tres áreas: recogida, entrada de descripción y salida de descripción.
func _initiate_detectors():
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)
	$DescriptionDetector.body_exited.connect(_on_hitbox_exit_description)

# Inicia la animación del pedestal y la animación de oscilación visual del ítem.
func _initiate_animations():
	$Pedestal/AnimatedSprite2D.play("default")
	$Visual/AnimationPlayer.play("oscillate")

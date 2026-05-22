extends Control

# =============================================================================
# REFERENCIAS Y ESTADO
# =============================================================================

@onready var animation: AnimationPlayer = $AnimationPlayer

# Evita reproducir la animación de aparición más de una vez por habilidad equipada
var first_time: bool = false


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	# El widget empieza oculto hasta que se equipe una habilidad
	hide()
	Signals.show_death_menu.connect(_on_death)


# =============================================================================
# CONTROL DE LA BARRA
# =============================================================================

# Establece directamente el valor de la barra de cooldown (0.0 = vacía, 1.0 = llena).
func set_value(value: float):
	$AbilityCooldownBar.value = value

# Conecta las señales de cooldown de una habilidad a este widget,
# desconectando primero las señales previas para evitar duplicados.
func connect_ability(ability):
	if ability.cooldown_started.is_connected(_on_cooldown_started):
		ability.cooldown_started.disconnect(_on_cooldown_started)
	if ability.cooldown_progress.is_connected(_on_cooldown_progress):
		ability.cooldown_progress.disconnect(_on_cooldown_progress)
	if ability.cooldown_finished.is_connected(_on_cooldown_finished):
		ability.cooldown_finished.disconnect(_on_cooldown_finished)
	ability.cooldown_started.connect(_on_cooldown_started)
	ability.cooldown_progress.connect(_on_cooldown_progress)
	ability.cooldown_finished.connect(_on_cooldown_finished)


# =============================================================================
# CALLBACKS DE COOLDOWN
# =============================================================================

# Al iniciar el cooldown, resetea la barra a cero y la hace visible.
func _on_cooldown_started(_duration := 0.0):
	$AbilityCooldownBar.max_value = 1.0
	$AbilityCooldownBar.value = 0.0
	$AbilityCooldownBar.visible = true

# Actualiza el progreso de la barra cada tick del cooldown (valor entre 0.0 y 1.0).
func _on_cooldown_progress(progress):
	$AbilityCooldownBar.value = progress

# Llamado al terminar el cooldown. Actualmente sin comportamiento activo
# (las líneas comentadas eran opciones para ocultar la barra al finalizar).
func _on_cooldown_finished():
	#$AbilityCooldownBar.visible = false
	#$AbilityImage.visible = false
	#first_time = false
	#hide()
	pass


# =============================================================================
# RECOGIDA DE HABILIDAD
# =============================================================================

# Al equipar una habilidad: rellena la barra, cambia el icono y reproduce
# la animación de aparición del widget solo la primera vez.
func on_ability_pick(item_texture: String):
	$AbilityCooldownBar.value = 1.0
	change_image(item_texture)
	if !first_time:
		animation.play("ability_charge_bar_spawn")

# Muestra el widget y asigna la textura del icono de la habilidad.
func change_image(item_texture: String):
	show()
	$AbilityImage.texture = load(item_texture)


# =============================================================================
# VISIBILIDAD
# =============================================================================

# Oculta el widget al morir.
func _on_death():
	self.hide()

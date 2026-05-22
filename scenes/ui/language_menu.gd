extends Control

signal back_pressed

# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready():
	# Resalta el botón del idioma activo al abrir el menú
	update_button_colors()
	add_to_group("localizable")
	update_texts()
	# Conecta cada botón de idioma a su cambio de locale correspondiente
	$PanelContainer/VBoxContainer/English.pressed.connect(func(): change_language("en"))
	$PanelContainer/VBoxContainer/Spanish.pressed.connect(func(): change_language("es"))
	$Back.pressed.connect(_on_back_pressed)


# =============================================================================
# NAVEGACIÓN
# =============================================================================

# Emite la señal de vuelta atrás y destruye el menú.
func _on_back_pressed():
	back_pressed.emit()
	queue_free()


# =============================================================================
# CAMBIO DE IDIOMA
# =============================================================================

# Aplica el nuevo locale, actualiza los textos y el resaltado de botones.
func change_language(locale: String):
	UserSettings.set_language(locale)
	update_texts()
	update_button_colors()


# =============================================================================
# LOCALIZACIÓN
# =============================================================================

# Actualiza los textos traducibles del menú según el idioma activo.
func update_texts():
	$Select.text = tr("menu_select_language")
	$Back.text = tr("menu_back")


# =============================================================================
# RESALTADO DEL IDIOMA ACTIVO
# =============================================================================

# Resetea el color de todos los botones a blanco y resalta en azul el idioma actual.
func update_button_colors():
	var locale = LanguageManager.current_locale
	$PanelContainer/VBoxContainer/English.modulate = Color(1.0, 1.0, 1.0, 1.0)
	$PanelContainer/VBoxContainer/Spanish.modulate = Color(1.0, 1.0, 1.0, 1.0)
	match locale:
		"en":
			$PanelContainer/VBoxContainer/English.modulate = Color(0.2, 0.6, 1.0)
		"es":
			$PanelContainer/VBoxContainer/Spanish.modulate = Color(0.2, 0.6, 1.0)

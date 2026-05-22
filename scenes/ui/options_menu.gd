extends Control

signal back_pressed

# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	# Registra el nodo como localizable y se suscribe a cambios de idioma
	add_to_group("localizable")
	LanguageManager.language_changed.connect(update_texts)
	update_texts()

	# Traduce las etiquetas de los sliders de audio
	$AudioOptions/VBoxContainer/MasterLabel.text = tr("master_volume")
	$AudioOptions/VBoxContainer/SFXLabel.text = tr("sfx_volume")
	$AudioOptions/VBoxContainer/MusicLabel.text = tr("music_volume")

	# Inicializa los sliders con los valores guardados en UserSettings
	$AudioOptions/VBoxContainer/MasterSlider.value = UserSettings.volume_master
	$AudioOptions/VBoxContainer/SFXSlider.value = UserSettings.volume_sfx
	$AudioOptions/VBoxContainer/MusicSlider.value = UserSettings.volume_music


# =============================================================================
# LOCALIZACIÓN
# =============================================================================

# Actualiza los textos de los botones al cambiar de idioma.
func update_texts():
	$Apply.text = tr("apply_settings")
	$Back.text = tr("menu_back")


# =============================================================================
# APLICAR AJUSTES
# =============================================================================

# Lee los valores actuales de los sliders, los aplica al AudioServer y los guarda.
# Si existe el desplegable de idioma, también aplica y guarda el idioma seleccionado.
func _on_apply_pressed():
	var master = $AudioOptions/VBoxContainer/MasterSlider.value
	var sfx = $AudioOptions/VBoxContainer/SFXSlider.value
	var music = $AudioOptions/VBoxContainer/MusicSlider.value

	# Convierte los valores lineales [0-1] a decibelios y los aplica a los buses
	AudioServer.set_bus_volume_db(0, linear_to_db(master))
	AudioServer.set_bus_volume_db(1, linear_to_db(sfx))
	AudioServer.set_bus_volume_db(2, linear_to_db(music))

	UserSettings.set_all_volumes(master, music, sfx)
	UserSettings.save_settings()

	# Aplica el idioma si el desplegable de idioma está presente en la escena
	if has_node("LangDropdown"):
		var lang = $LangDropdown.selected_language_cod
		UserSettings.set_language(lang)
		UserSettings.save_settings()


# =============================================================================
# CERRAR MENÚ
# =============================================================================

# Emite la señal back_pressed para notificar al padre y destruye el panel.
func _on_back_pressed():
	emit_signal("back_pressed")
	queue_free()

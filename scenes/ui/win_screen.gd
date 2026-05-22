extends Node2D

# =============================================================================
# REFERENCIAS A NODOS
# =============================================================================

# Etiqueta del mensaje de victoria
@onready var win_message: RichTextLabel = $YouEscaped
# Contenedor de botones de la pantalla de victoria
@onready var button_manager: Control = $ButtonManager
# Botón para volver al menú principal
@onready var back_menu_button: Button = $ButtonManager/HBoxContainer/GoBackToMenu

# Instancias de submenús dinámicos (reservadas para uso futuro)
var options_instance: Control
var languages_instance: Control
var in_options: bool = false
var in_audio: bool = false
var in_language: bool = false


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	add_to_group("localizable")
	update_texts()
	button_manager.show()
	AudioManager.play_music("victory_screen", true, -20.0)


# =============================================================================
# LOCALIZACIÓN
# =============================================================================

# Actualiza los textos traducibles de la pantalla de victoria.
func update_texts() -> void:
	back_menu_button.text = tr("menu_back_to_menu")
	win_message.text = tr("win_screen_you_win")


# =============================================================================
# INPUT
# =============================================================================

# Consume el evento Escape para evitar que lo procese otro nodo.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("escape"):
		return
	get_viewport().set_input_as_handled()


# =============================================================================
# NAVEGACIÓN
# =============================================================================

# Detiene la música y vuelve al menú principal.
func _on_go_back_to_menu_pressed() -> void:
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

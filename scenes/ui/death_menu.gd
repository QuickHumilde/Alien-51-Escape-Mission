extends Control

# =============================================================================
# REFERENCIAS A NODOS
# =============================================================================

# Etiqueta del título del menú de muerte
@onready var title_label = $RichTextLabel
# Botones de reiniciar y salir
@onready var restart_label = $PanelContainer/VBoxContainer/Control/Restart
@onready var quit_label = $PanelContainer/VBoxContainer/Control/Quit
# Reproductor de música de fondo (se asigna si es necesario)
@onready var bg_music: AudioStreamPlayer2D


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready():
	add_to_group("localizable")
	LanguageManager.language_changed.connect(update_texts)
	update_texts()
	# Inicia la animación de desenfoque de fondo
	$AnimationPlayer.play("blur")
	_connect_player_signals()
	# El menú empieza oculto hasta que el jugador muere
	hide()


# =============================================================================
# LOCALIZACIÓN
# =============================================================================

# Actualiza los textos del menú según el idioma activo.
func update_texts():
	title_label.text = tr("death_message")
	restart_label.text = tr("menu_restart")
	quit_label.text = tr("menu_quit")


# =============================================================================
# CONEXIÓN DE SEÑALES
# =============================================================================

# Conecta las señales globales de muerte y revive del jugador.
func _connect_player_signals():
	Signals.player_death.connect(pause)
	Signals.show_death_menu.connect(show_menu)
	Signals.player_revive.connect(resume)


# =============================================================================
# PAUSA Y REANUDACIÓN
# =============================================================================

# Reactiva el juego al revivir: despausa el árbol y oculta el menú.
func resume():
	Signals.player_is_dead = false
	get_tree().paused = false
	hide()

# Pausa el árbol de escena en el momento de la muerte (antes de mostrar el menú).
func pause():
	Signals.player_is_dead = true
	get_tree().paused = true

# Muestra el menú de muerte y arranca la música correspondiente.
func show_menu():
	play_music()
	show()


# =============================================================================
# BOTONES
# =============================================================================

# Vuelve al menú principal sin borrar el save: solo resetea flags de sesión.
func _on_quit_pressed():
	Signals.player_is_dead = false
	SaveManager.reset_session_flags()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# Inicia una nueva partida desde cero: borra el save, resetea todos los managers
# y carga el generador de mundo.
func _on_restart_pressed():
	SaveManager.clear_save()
	GameManager.reset()
	ItemManager.clear_removed_items()
	GameManager.continue_requested = false
	get_tree().paused = false
	Signals.player_is_dead = false
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/map/world_generator.tscn")


# =============================================================================
# AUDIO
# =============================================================================

# Reproduce la música del menú de muerte.
func play_music():
	AudioManager.play_music("death_menu")

extends Control

# =============================================================================
# REFERENCIAS A NODOS
# =============================================================================

# Botones del panel de pausa principal
@onready var resume_label = $PanelContainer/VBoxContainer/Resume
@onready var quit_label = $PanelContainer/VBoxContainer/Quit
@onready var pause_panel = $PanelContainer
@onready var options_label = $PanelContainer/VBoxContainer/Options

# Panel y botones del submenú de opciones
@onready var options_panel = $OptionsContainer
@onready var audio_label = $OptionsContainer/VBoxContainer/Audio
@onready var language_label = $OptionsContainer/VBoxContainer/Language
@onready var back_label = $OptionsContainer/VBoxContainer/Back

# Aviso y sprite de la última posición del ratón (para restaurarla al reanudar)
@onready var mouse_warning_container = $MouseWarningContainer
@onready var mouse_warning_label = $MouseWarningContainer/MouseWarning
@onready var mouse_last_position_sprite = $MousePosition

# Instancias activas de submenús dinámicos (null si no están abiertos)
var options_instance: Control
var languages_instance: Control

# Flags de estado de navegación por submenús
var in_options: bool = false
var in_language: bool = false
var in_audio: bool = false

# Posición del ratón guardada al pausar para restaurarla al reanudar
var last_mouse_position: Vector2

# Escenas precargadas de los submenús de ajustes
@onready var options_scene := preload("res://scenes/ui/options_volume_menu.tscn")
@onready var languages_scene := preload("res://scenes/ui/language_menu.tscn")


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready():
	add_to_group("localizable")
	LanguageManager.language_changed.connect(update_texts)
	update_texts()
	$AnimationPlayer.play("RESET")
	# El menú empieza oculto; se muestra al pausar
	hide()


# =============================================================================
# LOCALIZACIÓN
# =============================================================================

# Actualiza todos los textos traducibles del menú de pausa y sus submenús.
func update_texts():
	resume_label.text = tr("menu_resume")
	options_label.text = tr("menu_options")
	quit_label.text = tr("menu_quit")
	audio_label.text = tr("menu_audio")
	language_label.text = tr("menu_language")
	back_label.text = tr("menu_back")
	mouse_warning_label.text = tr("mouse_warning")


# =============================================================================
# PAUSA Y REANUDACIÓN
# =============================================================================

# Reanuda el juego: despausa el árbol, restaura el ratón a su posición anterior
# y reproduce la animación de desenfoque en reversa.
func resume():
	get_tree().paused = false
	MouseController.teleport_mouse(last_mouse_position)
	$AnimationPlayer.play_backwards("blur")
	hide()

# Pausa el juego: guarda la posición actual del ratón, pausa el árbol
# y reproduce la animación de desenfoque.
func pause():
	last_mouse_position = get_global_mouse_position()
	mouse_last_position_sprite.position = last_mouse_position
	get_tree().paused = true
	show()
	$AnimationPlayer.play("blur")


# =============================================================================
# INPUT (ESCAPE)
# =============================================================================

# Gestiona la tecla Escape según el nivel de submenú activo.
# No actúa si el jugador está muerto.
func testEsc():
	if Signals.player_is_dead:
		return

	if not Input.is_action_just_pressed("escape"):
		return

	if in_audio:
		_on_audio_closed()
		return

	if in_language:
		_on_language_closed()
		return

	if in_options:
		_on_options_closed()
		return

	# Alterna pausa/reanudación si no hay submenú abierto
	if get_tree().paused:
		resume()
	else:
		pause()

func _process(_delta):
	testEsc()


# =============================================================================
# BOTONES DEL MENÚ DE PAUSA
# =============================================================================

func _on_resume_pressed():
	resume()

# Vuelve al menú principal: limpia instancias dinámicas, despausa y emite señal.
func _on_quit_pressed():
	SaveManager.reset_session_flags()
	_cleanup_dynamic_instances()
	get_tree().paused = false
	Signals.back_to_main_menu.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# Abre el submenú de opciones y oculta el panel de pausa principal.
func _on_options_pressed():
	in_options = true
	mouse_warning_container.hide()
	options_panel.show()
	pause_panel.hide()

# Cierra el submenú de opciones y vuelve al panel de pausa principal.
func _on_options_closed():
	in_options = false
	mouse_warning_container.show()
	if options_instance:
		if options_instance.back_pressed.is_connected(_on_audio_closed):
			options_instance.back_pressed.disconnect(_on_audio_closed)
		options_instance.queue_free()
		options_instance = null
	options_panel.hide()
	pause_panel.show()


# =============================================================================
# SUBMENÚ DE AUDIO
# =============================================================================

# Instancia y muestra el menú de volumen desde el submenú de opciones.
func _on_audio_pressed():
	in_audio = true
	options_instance = options_scene.instantiate()
	options_instance.back_pressed.connect(_on_audio_closed)
	add_child(options_instance)
	options_instance.show()
	options_panel.hide()

# Destruye el menú de volumen y vuelve al submenú de opciones.
func _on_audio_closed():
	in_audio = false
	if options_instance:
		if options_instance.back_pressed.is_connected(_on_audio_closed):
			options_instance.back_pressed.disconnect(_on_audio_closed)
		options_instance.queue_free()
		options_instance = null
	options_panel.show()


# =============================================================================
# SUBMENÚ DE IDIOMA
# =============================================================================

# Instancia y muestra el menú de idioma desde el submenú de opciones.
func _on_language_pressed():
	in_language = true
	languages_instance = languages_scene.instantiate()
	languages_instance.back_pressed.connect(_on_language_closed)
	add_child(languages_instance)
	languages_instance.show()
	options_panel.hide()

# Destruye el menú de idioma, relocaliza textos y vuelve al submenú de opciones.
func _on_language_closed():
	in_language = false
	if languages_instance:
		if languages_instance.back_pressed.is_connected(_on_language_closed):
			languages_instance.back_pressed.disconnect(_on_language_closed)
		languages_instance.queue_free()
		languages_instance = null
	update_texts()
	options_panel.show()


# =============================================================================
# LIMPIEZA DE INSTANCIAS DINÁMICAS
# =============================================================================

# Destruye y desconecta cualquier submenú instanciado dinámicamente.
# Se llama al salir al menú principal para no dejar nodos huérfanos.
func _cleanup_dynamic_instances():
	if options_instance:
		if options_instance.back_pressed.is_connected(_on_audio_closed):
			options_instance.back_pressed.disconnect(_on_audio_closed)
		options_instance.queue_free()
		options_instance = null
	if languages_instance:
		if languages_instance.back_pressed.is_connected(_on_language_closed):
			languages_instance.back_pressed.disconnect(_on_language_closed)
		languages_instance.queue_free()
		languages_instance = null

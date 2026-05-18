extends Control

@onready var resume_label = $PanelContainer/VBoxContainer/Resume
@onready var quit_label = $PanelContainer/VBoxContainer/Quit
@onready var pause_panel = $PanelContainer
@onready var options_label = $PanelContainer/VBoxContainer/Options
@onready var options_panel = $OptionsContainer
@onready var audio_label = $OptionsContainer/VBoxContainer/Audio
@onready var language_label = $OptionsContainer/VBoxContainer/Language
@onready var back_label = $OptionsContainer/VBoxContainer/Back
@onready var mouse_warning_container = $MouseWarningContainer
@onready var mouse_warning_label = $MouseWarningContainer/MouseWarning
@onready var mouse_last_position_sprite = $MousePosition

var options_instance: Control
var languages_instance: Control
var in_options :bool = false
var in_language:bool = false
var in_audio:bool = false
var last_mouse_position: Vector2

@onready var options_scene := preload("res://scenes/ui/options_volume_menu.tscn")
@onready var languages_scene := preload("res://scenes/ui/language_menu.tscn")

func _ready():
	add_to_group("localizable")
	LanguageManager.language_changed.connect(update_texts)
	update_texts()
	$AnimationPlayer.play("RESET")
	hide()

func update_texts():
	resume_label.text = tr("menu_resume")
	options_label.text = tr("menu_options")
	quit_label.text = tr("menu_quit")
	audio_label.text = tr("menu_audio")
	language_label.text = tr("menu_language")
	back_label.text = tr("menu_back")
	mouse_warning_label.text = tr("mouse_warning")

func resume():
	get_tree().paused = false
	MouseController.teleport_mouse(last_mouse_position)
	$AnimationPlayer.play_backwards("blur")
	hide()
	
func pause():
	last_mouse_position = get_global_mouse_position()
	mouse_last_position_sprite.position = last_mouse_position
	get_tree().paused = true
	show()
	$AnimationPlayer.play("blur")

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

	if get_tree().paused:
		resume()
	else:
		pause()

func _on_resume_pressed():
	resume()

func _on_quit_pressed():
	SaveManager.reset_session_flags()
	_cleanup_dynamic_instances()
	get_tree().paused = false
	Signals.back_to_main_menu.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_options_pressed():
	in_options = true
	mouse_warning_container.hide()
	options_panel.show()
	pause_panel.hide()

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

func _on_audio_pressed():
	in_audio = true
	options_instance = options_scene.instantiate()
	options_instance.back_pressed.connect(_on_audio_closed)
	add_child(options_instance)
	options_instance.show()
	options_panel.hide()

func _on_audio_closed():
	in_audio = false
	if options_instance:
		if options_instance.back_pressed.is_connected(_on_audio_closed):
			options_instance.back_pressed.disconnect(_on_audio_closed)
		options_instance.queue_free()
		options_instance = null
	options_panel.show()
	
func _on_language_pressed():
	in_language = true
	languages_instance = languages_scene.instantiate()
	languages_instance.back_pressed.connect(_on_language_closed)
	add_child(languages_instance)
	languages_instance.show()
	options_panel.hide()

func _on_language_closed():
	in_language = false
	if languages_instance:
		if languages_instance.back_pressed.is_connected(_on_language_closed):
			languages_instance.back_pressed.disconnect(_on_language_closed)
		languages_instance.queue_free()
		languages_instance = null
	update_texts()
	options_panel.show()

func _process(_delta):
	testEsc()

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

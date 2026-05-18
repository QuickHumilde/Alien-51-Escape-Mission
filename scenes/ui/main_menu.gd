extends Node2D

@onready var button_manager: Control = $ButtonManager
@onready var start_button: Button = $ButtonManager/VBoxContainer/Start
@onready var options_button: Button = $ButtonManager/VBoxContainer/Options
@onready var quit_button: Button = $ButtonManager/VBoxContainer/Quit
@onready var continue_button: Button = $ButtonManager/VBoxContainer/Continue
@onready var new_game_button: Button = $ButtonManager/VBoxContainer/NewGame
@onready var title_label: RichTextLabel = $Title

@onready var options_container: Control = $OptionsContainer
@onready var audio_button: Button = $OptionsContainer/VBoxContainer/Audio
@onready var language_button: Button = $OptionsContainer/VBoxContainer/Language
@onready var back_button: Button = $OptionsContainer/VBoxContainer/Back
@onready var tutorial_button: Button = $TutorialButton

@onready var options_scene := preload("res://scenes/ui/options_volume_menu.tscn")
@onready var languages_scene := preload("res://scenes/ui/language_menu.tscn")

var options_instance: Control
var languages_instance: Control

var in_options: bool = false
var in_audio: bool = false
var in_language: bool = false

func _ready() -> void:
	add_to_group("localizable")
	LanguageManager.language_changed.connect(update_texts)
	update_texts()

	options_container.hide()
	button_manager.show()
	AudioManager.play_music("main_menu", true, -20.0)
	continue_button.visible = SaveManager.has_save()

func update_texts() -> void:
	start_button.text = tr("menu_start")
	options_button.text = tr("menu_options")
	quit_button.text = tr("menu_quit")
	new_game_button.text = tr("menu_new_game")
	continue_button.text = tr("menu_continue")

	audio_button.text = tr("menu_audio")
	language_button.text = tr("menu_language")
	back_button.text = tr("menu_back")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("escape"):
		return

	if in_audio:
		_on_audio_closed()
		get_viewport().set_input_as_handled()
		return

	if in_language:
		_on_language_closed()
		get_viewport().set_input_as_handled()
		return

	if in_options:
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()

func _on_start_pressed() -> void:
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/map/world_generator.tscn")

func _on_options_pressed() -> void:
	in_options = true
	button_manager.hide()
	options_container.show()
	title_label.hide()
	tutorial_button.hide()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_back_pressed() -> void:
	in_options = false
	options_container.hide()
	button_manager.show()
	title_label.show()
	tutorial_button.show()

func _on_continue_pressed() -> void:
	AudioManager.stop_music()
	GameManager.continue_requested = true
	get_tree().change_scene_to_file("res://scenes/map/world_generator.tscn")

func _on_new_game_pressed() -> void:
	AudioManager.stop_music()
	SaveManager.reset_session_flags()
	SaveManager.clear_save()
	GameManager.reset()
	ItemManager.clear_removed_items()
	GameManager.continue_requested = false
	get_tree().change_scene_to_file("res://scenes/map/world_generator.tscn")

func _on_audio_pressed() -> void:
	if in_audio or in_language:
		return

	in_audio = true
	options_instance = options_scene.instantiate()
	options_instance.back_pressed.connect(_on_audio_closed)
	add_child(options_instance)

	options_instance.show()
	options_container.hide()

func _on_audio_closed() -> void:
	in_audio = false
	if options_instance:
		options_instance.queue_free()
		options_instance = null

	options_container.show()

func _on_language_pressed() -> void:
	if in_audio or in_language:
		return

	in_language = true
	languages_instance = languages_scene.instantiate()
	languages_instance.back_pressed.connect(_on_language_closed)
	add_child(languages_instance)
	languages_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	languages_instance.set_offsets_preset(Control.PRESET_FULL_RECT)
	languages_instance.show()
	options_container.hide()

func _on_language_closed() -> void:
	in_language = false
	if languages_instance:
		languages_instance.queue_free()
		languages_instance = null

	update_texts()
	options_container.show()


func _on_tutorial_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/tutorial_screen.tscn")

extends Node2D

@onready var win_message: Label = $YouEscaped
@onready var button_manager: Control = $ButtonManager
@onready var back_menu_button: Button = $ButtonManager/GoBackToMenu

var options_instance: Control
var languages_instance: Control

var in_options: bool = false
var in_audio: bool = false
var in_language: bool = false

func _ready() -> void:
	add_to_group("localizable")
	update_texts()

	button_manager.show()
	AudioManager.play_music("tutorial_screen", true, -20.0)

func update_texts() -> void:
	back_menu_button.text = tr("menu_back_to_menu")
	win_message.text = tr("win_screen_you_win")
	
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("escape"):
		return

	get_viewport().set_input_as_handled()

func _on_go_back_to_menu_pressed() -> void:
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

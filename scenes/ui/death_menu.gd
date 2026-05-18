extends Control

@onready var title_label = $RichTextLabel
@onready var restart_label = $PanelContainer/VBoxContainer/Control/Restart
@onready var quit_label = $PanelContainer/VBoxContainer/Control/Quit
@onready var bg_music: AudioStreamPlayer2D

func _ready():
	add_to_group("localizable")
	LanguageManager.language_changed.connect(update_texts)
	update_texts()
	$AnimationPlayer.play("blur")
	_connect_player_signals()
	hide()

func update_texts():
	title_label.text=tr("death_message")
	restart_label.text=tr("menu_restart")
	quit_label.text=tr("menu_quit")

func _connect_player_signals():
	Signals.player_death.connect(pause)
	Signals.show_death_menu.connect(show_menu)
	Signals.player_revive.connect(resume)

func resume():
	Signals.player_is_dead = false
	get_tree().paused = false
	hide()

func pause():
	Signals.player_is_dead = true
	get_tree().paused = true

func show_menu():
	play_music()
	show()

func _on_quit_pressed():
	Signals.player_is_dead = false
	SaveManager.reset_session_flags()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_restart_pressed():
	SaveManager.clear_save()
	GameManager.reset()
	ItemManager.clear_removed_items()
	GameManager.continue_requested = false
	get_tree().paused = false
	Signals.player_is_dead = false
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/map/world_generator.tscn")

func play_music():
	AudioManager.play_music("death_menu")

extends Control

@onready var title_label = $RichTextLabel
@onready var restart_label = $PanelContainer/VBoxContainer/Control/Restart
@onready var quit_label = $PanelContainer/VBoxContainer/Control/Quit
var music = preload("res://assets/audio/music/DeathMusic.mp3")
@onready var bg_music: AudioStreamPlayer2D

func _ready():
	setup_audio()
	title_label.text=tr("death_message")
	restart_label.text=tr("menu_restart")
	quit_label.text=tr("menu_quit")
	$AnimationPlayer.play("blur")
	_connect_player_signals()
	hide()

func _connect_player_signals():
	Signals.player_death.connect(pause)

func resume():
	Signals.player_is_dead = false	
	get_tree().paused = false
	hide()

func pause():
	play_music()
	Signals.player_is_dead = true
	get_tree().paused = true
	show()

func _on_quit_pressed():
	get_tree().quit()

func _on_restart_pressed():
	resume()
	get_tree().reload_current_scene()

func setup_audio():
	bg_music = AudioStreamPlayer2D.new()
	bg_music.name = "BackgroundMusic"
	bg_music.bus = "Music"
	bg_music.max_polyphony = 16
	add_child(bg_music)

func play_music():
	bg_music.stream = music
	bg_music.volume_db = 0.0
	bg_music.pitch_scale = 1.0
	bg_music.play()

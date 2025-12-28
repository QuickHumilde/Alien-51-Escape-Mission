extends Control

@onready var resume_label = $PanelContainer/VBoxContainer/Resume
@onready var quit_label = $PanelContainer/VBoxContainer/Quit
@onready var pause_panel = $PanelContainer
@onready var options_panel = $PanelContainer/VBoxContainer/Options
@onready var options_scene := preload("res://scenes/ui/options_menu.tscn")

var options_instance: Control
var in_options :bool = false

func _ready():
	resume_label.text = tr("menu_resume")
	options_panel.text = tr("menu_options")
	quit_label.text = tr("menu_quit")
	$AnimationPlayer.play("RESET")
	hide()

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	hide()
	
func pause():
	get_tree().paused = true
	show()
	$AnimationPlayer.play("blur")

func testEsc():
	if Signals.player_is_dead:
		return

	# Si estamos en opciones, ESC debe cerrar opciones
	if in_options and Input.is_action_just_pressed("escape"):
		_on_options_closed()
		return

	# Si NO estamos en opciones, ESC controla pausa
	if Input.is_action_just_pressed("escape") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("escape") and get_tree().paused:
		resume()

func _on_resume_pressed():
	resume()

func _on_quit_pressed():
	get_tree().quit()

func _on_options_pressed():
	in_options = true
	options_instance = options_scene.instantiate()
	options_instance.back_pressed.connect(_on_options_closed)
	add_child(options_instance)
	options_instance.show()
	pause_panel.hide()

func _on_options_closed():
	in_options = false
	if options_instance:
		options_instance.queue_free()
	pause_panel.show()

func _process(delta):
	testEsc()

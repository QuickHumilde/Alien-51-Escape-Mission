extends Control

func _ready():
	$AnimationPlayer.play("blur")
	_connect_player_signals()
	hide()

func _connect_player_signals():
	Signals.player_death.connect(pause)

func resume():
	get_tree().paused = false
	hide()
	
func pause():
	get_tree().paused = true
	show()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_restart_pressed():
	resume()
	get_tree().reload_current_scene()

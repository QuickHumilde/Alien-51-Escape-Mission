extends Node

# =============================================================================
# INPUT
# =============================================================================

# Alterna entre pantalla completa y modo ventana al pulsar la acción "ui_fullscreen".
func _input(event):
	if event.is_action_pressed("ui_fullscreen"):
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

extends Node

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func teleport_mouse(position : Vector2):
	get_viewport().warp_mouse(position)

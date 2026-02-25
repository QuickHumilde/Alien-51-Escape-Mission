extends Node

var game_time_scale : float = 1.0

func _ready() -> void:
	Engine.time_scale = game_time_scale

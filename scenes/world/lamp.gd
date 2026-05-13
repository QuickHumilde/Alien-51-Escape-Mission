extends PointLight2D

var flicker_chance: float = 0.002
var flicker_time: float = 0.05
var flickering: bool = false

func _process(_delta):
	if not flickering and randf() < flicker_chance:
		_start_flicker()

func _start_flicker():
	flickering = true
	var original: float = energy
	energy = original * 0.3
	await get_tree().create_timer(flicker_time).timeout
	energy = original
	flickering = false

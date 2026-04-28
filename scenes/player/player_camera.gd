extends Camera2D

var shake_strength: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
	Signals.shake_camera.connect(shake)

func shake(amount: float) -> void:
	shake_strength = amount

func _process(delta: float) -> void:
	if shake_strength > 0.01:
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
	else:
		offset = Vector2.ZERO

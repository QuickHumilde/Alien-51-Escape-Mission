extends AnimatedSprite2D

func _ready() -> void:
	Signals.wii_pointer_activated.connect(_on_wii_pointer_activated)

func _process(delta):
	global_position = get_viewport().get_mouse_position()

func _on_wii_pointer_activated():
	self.play("wii_pointer")

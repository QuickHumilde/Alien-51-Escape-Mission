extends AnimatedSprite2D

func _ready() -> void:
	Signals.wii_pointer_activated.connect(_on_wii_pointer_activated)
	Signals.show_death_menu.connect(_on_show_death_menu)

func _process(_delta):
	global_position = get_viewport().get_mouse_position()

func _on_wii_pointer_activated():
	self.play("wii_pointer")
	
func _on_show_death_menu():
	self.play("default")

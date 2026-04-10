extends Item

@export var ext_id: int = 22

func _ready():
	id = 22
	price = 5
	name_key = "item_console_controller_name"
	desc_key = "item_console_controller_desc"
	item_texture = "res://assets/sprites/WiiController.png"
	super._ready()
	
func give_changes(_body: Character):
	Signals.wii_pointer_activated.emit()
	destroy_on_pickup()

func destroy_on_pickup():
	AudioManager.play_sfx("wii_startup", -10)
	super.destroy_on_pickup()

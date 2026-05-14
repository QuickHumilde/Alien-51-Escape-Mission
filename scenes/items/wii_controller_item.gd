extends Item

@export var ext_id: int = 22

func _ready():
	id = 22
	price = 5
	name_key = "item_console_controller_name"
	desc_key = "item_console_controller_desc"
	item_texture = "res://assets/sprites/items/WiiController.png"
	super._ready()
	
func give_changes(body: Character):
	var wii_controller_modifier = WiiControllerModifierItem.new(body)
	body.items.give_modifiers(wii_controller_modifier)
	destroy_on_pickup()

func destroy_on_pickup():
	AudioManager.play_sfx("wii_startup", -10)
	super.destroy_on_pickup()

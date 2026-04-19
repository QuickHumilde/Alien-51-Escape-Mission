extends Item

@export var weapon_id : int = 9
@export var ext_id: int = 24

func _ready():
	id = 24
	name_key="item_shuriken_weapon_name"
	desc_key="item_shuriken_weapon_desc"
	item_texture = "res://assets/sprites/items/ShurikenItem.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

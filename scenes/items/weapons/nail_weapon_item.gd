extends Item

@export var weapon_id : int = 4
@export var ext_id: int = 19

func _ready():
	id = 319
	name_key="item_nail_weapon_name"
	desc_key="item_nail_weapon_desc"
	item_texture = "res://assets/sprites/weapons/Nail.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

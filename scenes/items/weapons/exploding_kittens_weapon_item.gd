extends Item

@export var weapon_id = 6
@export var ext_id: int = 14

func _ready():
	id = 14
	name_key="item_exploding_kitens_weapon_name"
	desc_key="item_exploding_kitens_weapon_desc"
	item_texture = "res://assets/sprites/weapons/ExplodingKittens.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

extends Item

@export var weapon_id : int = 10
@export var ext_id: int = 25

func _ready():
	id = 25
	name_key="item_eye_of_the_witch_name"
	desc_key="item_eye_of_the_witch_desc"
	item_texture = "res://assets/sprites/items/EyeOfTheWitchItem.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

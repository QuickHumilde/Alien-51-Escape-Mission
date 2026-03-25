extends Item
class_name PistolGunItem

@export var weapon_id : int = 2
@export var ext_id: int = 2

func _ready():
	id = 2
	name_key="item_pistol_gun_name"
	desc_key="item_pistol_gun_desc"
	item_texture = "res://assets/sprites/weapons/PistolGun.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

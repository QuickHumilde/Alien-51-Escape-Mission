extends Item
class_name PistolGunItem

@export var id : int = 2

func _ready() -> void:
	name_key="item_pistol_gun_name"
	desc_key="item_pistol_gun_desc"
	item_texture = "res://assets/sprites/weapons/ranged/PistolGun.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(id)
	destroy_on_pickup()

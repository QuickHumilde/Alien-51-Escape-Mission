extends Item
class_name PistolGunItem

var weapon_name : String = "pistol"

func _ready() -> void:
	id=2
	name_key="item_pistol_gun_name"
	desc_key="item_pistol_gun_desc"
	item_texture = "res://assets/sprites/weapons/ranged/PistolGun.png"
	_initiate_detectors()

func give_changes(body: Character):
	body.items.give_weapon(weapon_name)
	queue_free()

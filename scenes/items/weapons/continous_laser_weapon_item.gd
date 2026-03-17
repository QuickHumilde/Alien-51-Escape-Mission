extends Item

@export var id : int = 12
@export var weapon_id : int = 5

func _ready() -> void:
	name_key="item_continous_laser_weapon_name"
	desc_key="item_continous_laser_weapon_desc"
	item_texture = "res://assets/sprites/weapons/ContinousLaserWeapon.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

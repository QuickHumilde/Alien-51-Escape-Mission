extends Item

@export var weapon_id : int = 7
@export var ext_id: int = 16

func _ready():
	id = 16
	name_key="item_shotgun_inter_mark_gun_name"
	desc_key="item_shotgun_inter_mark_gun_desc"
	item_texture = "res://assets/sprites/weapons/ShotgunInterrogationMark.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

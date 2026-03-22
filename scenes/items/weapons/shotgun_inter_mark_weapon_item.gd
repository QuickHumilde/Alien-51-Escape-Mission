extends Item

@export var id : int = 16
@export var weapon_id : int = 7

func _ready() -> void:
	name_key="item_shotgun_inter_mark_gun_name"
	desc_key="item_shotgun_inter_mark_gun_desc"
	item_texture = "res://assets/sprites/weapons/ShotgunInterrogationMark.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

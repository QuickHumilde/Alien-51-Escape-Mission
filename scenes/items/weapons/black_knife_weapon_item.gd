extends Item

@export var weapon_id : int = 8
@export var ext_id: int = 23

func _ready():
	id = 23
	name_key="item_black_knife_weapon_name"
	desc_key="item_black_knife_weapon_desc"
	item_texture = "res://assets/sprites/items/PreBlackKnife.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

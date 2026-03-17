extends Item

@export var id : int = 14
@export var weapon_id = 6

func _ready() -> void:
	name_key="item_exploding_kitens_weapon_name"
	desc_key="item_exploding_kitens_weapon_desc"
	item_texture = "res://assets/sprites/weapons/ExplodingKittens.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(weapon_id)
	destroy_on_pickup()

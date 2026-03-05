extends Item

@export var id : int = 3

func _ready() -> void:
	name_key="item_blue_marker_weapon_name"
	desc_key="item_blue_marker_weapon_desc"
	item_texture = "res://assets/sprites/weapons/BlueMarker.png"
	super._ready()

func give_changes(body: Character):
	body.items.give_weapon(id)
	destroy_on_pickup()

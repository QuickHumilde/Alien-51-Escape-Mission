extends Item

var speed_increase: float = 25.0
@export var ext_id: int = 4

func _ready():
	id = 4
	name_key= "item_ninja_headband_name"
	desc_key="item_ninja_headband_desc"
	item_texture = "res://assets/sprites/items/NinjaHeadband_Item.png"
	super._ready()

func give_changes(body: Character):
	body.items.modify_speed(speed_increase)
	destroy_on_pickup()

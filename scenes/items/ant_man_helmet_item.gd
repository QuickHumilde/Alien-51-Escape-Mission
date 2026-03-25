extends Item

var size_disminution: float = -0.2
@export var ext_id: int = 5

func _ready():
	id = 5
	name_key="item_ant_man_helmet_name"
	desc_key="item_ant_man_helmet_desc"
	item_texture="res://assets/sprites/items/Ant-ManHelmet_Item.png"
	super._ready()

func give_changes(body: Character):
	body.stats.modify_size(size_disminution)
	destroy_on_pickup()

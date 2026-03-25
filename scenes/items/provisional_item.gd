extends Item
class_name ProvisionalItem

var speed_increase : float = 25
var max_health_increase : float = 2
var scale_increase : float = 0.25
@export var ext_id: int = 0

func _ready():
	id = 0
	name_key="item_provisional_item_name"
	desc_key="item_provisional_item_desc"
	item_texture = "res://assets/sprites/provisional/Player1-Front.png"
	super._ready()

func give_changes(body: Character):
	body.items.modify_speed(speed_increase)
	body.items.increase_max_health(max_health_increase)
	body.items.modify_size(scale_increase)
	destroy_on_pickup()

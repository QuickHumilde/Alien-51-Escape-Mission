extends Item

var health : float = 1
@export var id: int = 7

func _ready():
	name_key = "item_dai_name"
	desc_key = "item_dai_desc"
	item_texture = "res://assets/sprites/items/DAI_Item.png"
	super._ready()

func give_changes(body: Character):
	body.stats.increase_max_health(health)
	destroy_on_pickup()

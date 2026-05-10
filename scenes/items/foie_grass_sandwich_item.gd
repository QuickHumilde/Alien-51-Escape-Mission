extends Item

@export var ext_id: int = 28
var max_health_increase: float = 1.0

func _ready():
	id = 28
	price = 10
	name_key = "item_foie_gras_sandwich_name"
	desc_key = "item_foie_gras_sandwich_desc"
	item_texture = "res://assets/sprites/items/FoieGrasSandwichItem.png"
	super._ready()
	
func give_changes(body: Character):
	#var weights_controller_modifier = WeightsControllerModifierItem.new(body)
	#body.items.give_modifiers(weights_controller_modifier)
	body.stats.increase_max_health(max_health_increase)
	body.stats.heal(max_health_increase)
	destroy_on_pickup()

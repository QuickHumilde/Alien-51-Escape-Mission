extends Item
class_name DashAbilityItem

@export var ext_id: int = 11

func _ready():
	id = 11
	name_key = "item_dash_name"
	desc_key = "item_dash_desc"
	item_texture = "res://assets/sprites/items/Dash1_Item.png"
	super._ready()

func give_changes(body: Character):
	var dash_ability = DashAbility.new()
	dash_ability.get_player(body)
	Signals.item_picked.connect(dash_ability._on_item_picked)
	dash_ability.check_items(body)

	body.abilities.change_ability(dash_ability, self.global_position)
	
	destroy_on_pickup()

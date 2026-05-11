extends Item
class_name SummerChairAbilitysItem

@export var ext_id: int = 31

func _ready() -> void:
	id = ext_id
	name_key = "item_summer_chair_name"
	desc_key = "item_summer_chair_desc"
	item_texture = "res://assets/sprites/items/SummerChairItem.png"
	super._ready()

func give_changes(body: Character):
	var scythe_ability = ScytheAbility.new()
	scythe_ability.get_player(body)

	var hud = body.get_node("HUD/AbilityChargeBar")
	hud.connect_ability(scythe_ability)
	hud.on_ability_pick(item_texture)

	body.abilities.change_ability(scythe_ability, self.global_position)
	
	destroy_on_pickup()

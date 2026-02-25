extends Item
class_name DashAbilityItem

func _ready():
	name_key = "item_dai_name"
	desc_key = "item_dai_desc"
	item_texture = "res://assets/sprites/items/VoidHand.png"
	super._ready()

func give_changes(body: Character):
	var dash_ability = DashAbility.new()

	var hud = body.get_node("HUD/AbilityChargeBar")
	hud.connect_ability(dash_ability)
	hud.on_ability_pick(item_texture)

	body.abilities.change_ability(dash_ability)
	destroy_on_pickup()

extends Item
class_name ParryAbilityItem

@export var id: int = 17
var parry_scene = preload("res://scenes/extras/parry_ability_scene.tscn")

func _ready():
	name_key = "item_dash_name"
	desc_key = "item_dash_desc"
	item_texture = "res://assets/sprites/provisional/ParryAbility_3.png"
	super._ready()

func give_changes(body: Character):
	var inst = parry_scene.instantiate()
	body.add_child(inst)
	inst.global_position = body.global_position
	var hud = body.get_node("HUD/AbilityChargeBar")
	hud.connect_ability(inst)
	hud.on_ability_pick(item_texture)

	body.abilities.change_ability(inst)
	destroy_on_pickup()

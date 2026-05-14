extends Item
class_name ParryAbilityItem

@export var ext_id: int = 17
var parry_scene: PackedScene = preload("res://scenes/extras/parry_ability_scene.tscn")

func _ready():
	id = 17
	name_key = "item_parry_name"
	desc_key = "item_parry_desc"
	item_texture = "res://assets/sprites/items/ParryAbility.png"
	super._ready()

func give_changes(body: Character):
	call_deferred("_give_changes_deferred", body)

func _give_changes_deferred(body: Character):
	var inst = parry_scene.instantiate()
	inst.get_player(body)
	body.add_child(inst)
	inst.global_position = body.global_position

	body.abilities.change_ability(inst, self.global_position)

	destroy_on_pickup()

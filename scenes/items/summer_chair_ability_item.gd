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
	var ability := SummerChairAbility.new()
	ability.get_player(body)

	body.abilities.change_ability(ability, self.global_position)

	destroy_on_pickup()

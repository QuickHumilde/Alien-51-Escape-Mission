extends Item
class_name SummerChairAbilitysItem

@export var ext_id: int = 31
@export var uses_left: int = 3

func _ready() -> void:
	id = ext_id
	name_key = "item_summer_chair_name"
	desc_key = "item_summer_chair_desc"
	item_texture = "res://assets/sprites/items/SummerChairItem.png"
	super._ready()

func give_changes(body: Character):
	var ability := SummerChairAbility.new(uses_left)
	print(uses_left, "perro")
	ability.get_player(body)

	body.abilities.change_ability(ability, self.global_position)

	destroy_on_pickup()

func change_uses(uses: int):
	uses_left = uses
	print(uses_left, "mecafi")

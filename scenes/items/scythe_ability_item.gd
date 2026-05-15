extends Item
class_name ScytheAbilityItem

@export var ext_id: int = 27
@export var cooldown_left: float

func _ready():
	id = 27
	name_key = "item_scythe_ability_name"
	desc_key = "item_scythe_ability_desc"
	item_texture = "res://assets/sprites/items/ScytheItem.png"
	super._ready()

func give_changes(body: Character):
	var scythe_ability := ScytheAbility.new()
	scythe_ability.get_player(body)

	body.abilities.change_ability(scythe_ability, self.global_position)

	destroy_on_pickup()

extends Item
class_name HeavyArmorItem

var extra_health : float = 2
@export var id: int = 13

func _ready():
	name_key = "item_heavy_armor_name"
	desc_key = "item_heavy_armor_desc"
	item_texture = "res://assets/sprites/items/HeavyArmor.png"
	super._ready()

func give_changes(body: Character):
	var heavy_armor_modifier = HeavyArmorModifierItem.new(body)
	body.items.increase_extra_health(extra_health)
	body.items.give_modifiers(heavy_armor_modifier)
	destroy_on_pickup()

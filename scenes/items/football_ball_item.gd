extends Item
class_name FootballBallItem

@export var ext_id: int = 15

func _ready():
	id = 15
	name_key = "item_football_ball_name"
	desc_key = "item_football_ball_desc"
	item_texture = "res://assets/sprites/items/FootballBall.png"
	super._ready()

func give_changes(body: Character):
	var football_ball_modifier = FootballBallModifierItem.new(body)
	body.items.give_modifiers(football_ball_modifier)
	destroy_on_pickup()

extends Item

var health : float = 1
@onready var sprite = $Visual/AnimatedSprite2D
@export var id: int = 7

func _ready():
	name_key = "item_business_glasses_name"
	desc_key = "item_business_glasses_desc"
	item_texture = "res://assets/sprites/items/BusinessGlasses_Item.png"
	sprite.play("default")
	super._ready()

func give_changes(body: Character):
	body.stats.increase_max_health(health)
	destroy_on_pickup()
	
func destroy_on_pickup():
	AudioManager.play_sfx("big_shot_laugh", -10)
	super.destroy_on_pickup()

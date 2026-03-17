extends Item

var discount : float = -0.2
@onready var sprite = $Visual/AnimatedSprite2D
@export var id: int = 6

func _ready():
	name_key = "item_business_glasses_name"
	desc_key = "item_business_glasses_desc"
	item_texture = "res://assets/sprites/items/BusinessGlasses_Item.png"
	sprite.play("default")
	super._ready()

func give_changes(body: Character):
	GlobalModifiers.modify_shop_shop_price_mult(discount)
	destroy_on_pickup()
	
func destroy_on_pickup():
	AudioManager.play_sfx("big_shot_laugh", -10)
	super.destroy_on_pickup()

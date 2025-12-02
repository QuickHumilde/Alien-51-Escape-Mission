extends CharacterBody2D
class_name Character

@onready var sprite = $AnimatedSprite2D
@onready var movement = $Logic/Movement
@onready var animation = $Logic/Animation
@onready var combat = $Logic/Combat
@onready var stats = $Logic/Stats
@onready var items = $Logic/Items
@onready var weapon_holder = $WeaponHolder

func _ready():
	$Detector.area_entered.connect(_on_hitbox_enter)
	combat.init(weapon_holder)
	stats.sprite = sprite
	movement.character = self

func _process(_delta):
	movement.update(_delta, self)
	animation.update(self)
	combat.update(_delta, self)

func _physics_process(_delta):
	move_and_slide()

func _on_hitbox_enter(area):
	if area.is_in_group("damage_1"):
		stats.take_damage(1)

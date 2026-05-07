extends Pickup

@export var activable: bool = true

@onready var coin_scene: PackedScene = preload("res://scenes/pickup/coin.tscn")
@onready var health_scene: PackedScene = preload("res://scenes/pickup/health.tscn")
@onready var shield_scene: PackedScene = preload("res://scenes/pickup/shield_bowl.tscn")
@onready var enemy1_scene: PackedScene = preload("res://scenes/enemies/stickman/stickman_enemy.tscn")
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@export var coin_percentage: float = 45.0
@export var health_percentage: float = 15.0
@export var shield_percentage: float = 25.0
@export var enemy1_percentage: float = 10.0
var spawned: bool = false

func open_chest():
	if !spawned:
		var scene: PackedScene = _pick_weighted_scene()
		if scene == null:
			return

		var instant: Node = scene.instantiate()
		var parent = get_parent()
		sprite.play("open")
		parent.add_child(instant)
		instant.global_position = global_position
		spawned = true
	
func _pick_weighted_scene() -> PackedScene:
	var coin = max(0.0, coin_percentage)
	var health = max(0.0, health_percentage)
	var shield = max(0.0, shield_percentage)
	var enemy1 = max(0.0, enemy1_percentage)

	var total = coin + health + shield + enemy1
	if total <= 0.0:
		return null

	var random_number = randf() * total

	if random_number < coin:
		return coin_scene
	elif random_number < coin + health:
		return health_scene
	elif random_number < coin + health + shield:
		return shield_scene
	else:
		return enemy1_scene

func is_activable() -> bool:
	return activable

func _on_pick_up(_player : Character):
	if activable:
		call_deferred("open_chest")

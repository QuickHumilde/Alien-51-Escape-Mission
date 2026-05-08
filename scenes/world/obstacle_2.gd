extends StaticBody2D
class_name Obstacle2

var hits: int = 0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation: NavigationRegion2D = $FlyingNavigation
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var area_shape: Area2D = $Area2D

var broken: bool = false

func receive_hit():
	if broken:
		return

	hits += 1

	match hits:
		1:
			sprite.frame = 1
		2:
			sprite.frame = 2
		3:
			sprite.frame = 3
		4:
			sprite.frame = 4
			_break_obstacle()

func _break_obstacle():
	broken = true

	if is_in_group("obstacle"):
		remove_from_group("obstacle")

	collision_shape.set_deferred("disabled", true)
	area_shape.set_deferred("monitoring", false)
	area_shape.set_deferred("monitorable", false)

	Signals.obstacle_broken.emit(global_position)

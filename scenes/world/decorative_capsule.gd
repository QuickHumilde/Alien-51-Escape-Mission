extends StaticBody2D
class_name DecorativeCapsule

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D
enum Direcciones {Up, Down}
@export var direction: Direcciones = Direcciones.Up

func _ready() -> void:
	sprite.play("default")
	_set_hitboxes()
	
func _set_hitboxes():
	if direction == Direcciones.Down:
		hitbox.position.y = 25.0
		sprite.z_index = 13

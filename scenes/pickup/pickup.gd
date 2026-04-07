extends RigidBody2D
class_name Pickup

@onready var hitbox: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	hitbox.area_entered.connect(_on_area_entered)
	animation_player.play("spawn")

func _on_area_entered(body):
	if body.is_in_group("player"):
		var player: Character = body.get_parent()
		_on_pick_up(player)

func _on_pick_up(_player : Character):
	pass

func destroy():
	queue_free()

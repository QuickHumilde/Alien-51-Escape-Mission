extends Area2D

var damage: float = 1.0

func _ready() -> void:
	self.area_entered.connect(_on_area_entered)

func _on_area_entered(body):
	do_damage(body)

func do_damage(body):
	if body.is_in_group("enemy"):
		body.get_parent().take_damage(damage)
	elif body.is_in_group("player_tramp"):
		body.take_damage(damage)

extends RigidBody2D

@onready var area: Area2D = $Area2D
var damage: float = 1.0

func _ready() -> void:
	area.area_entered.connect(_on_area_entered)

func modify_damage(jis: float):
	if jis > 0:
		damage+=jis

func _on_area_entered(body):
	if body.is_in_group("enemy"):
		body.get_parent().take_damage(damage)
		

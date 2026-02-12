@abstract
extends Node2D
class_name Weapon

@onready var player= get_tree()
@onready var cooldown_timer = $ShootCooldown
@export var damage : float = 1.5
@export var knockback_force : float = 50.0
@export var self_knockback_force : float = 50.0
var is_attacking : bool = false
var id : int = 0
var lifetime: float = 0.0
var speed: float = 0.0

func give_knocback():
	var body = get_parent().get_parent()
	var knockback_direction = (body.global_position - global_position).normalized()
	get_parent().get_parent().apply_knockback(knockback_direction, self_knockback_force)

func destroy_weapon():
	var body = get_parent().get_parent()
	body.combat.remove_weapon(id)

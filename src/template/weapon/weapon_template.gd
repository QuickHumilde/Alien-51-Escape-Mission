@abstract
extends Node2D
class_name Weapon

@onready var cooldown_timer = $ShootCooldown
@export var damage : float = 1.5
@export var knockback_force : float = 50.0
var id : int = 0

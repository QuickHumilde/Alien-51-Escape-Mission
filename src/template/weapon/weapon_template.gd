@abstract
extends Node2D
class_name Weapon

@onready var player= get_tree()
@onready var cooldown_timer = $ShootCooldown
@export var damage : float = 1.5
@export var knockback_force : float = 50.0
var id : int = 0
var lifetime: float = 0.0
var speed: float = 0.0

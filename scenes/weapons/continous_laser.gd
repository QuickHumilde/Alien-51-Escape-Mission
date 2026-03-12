extends Weapon

@onready var laser_scene = preload("res://scenes/bullets/laser_beam.tscn")

var laser_instance : Node

func start_shooting(player_damage, _player_lifetime):
	if laser_instance:
		return

	laser_instance = laser_scene.instantiate()
	laser_instance.damage_per_second += player_damage * 0.5
	laser_instance.position = Vector2.ZERO
	laser_instance.rotation = 0.0
	laser_instance.max_length = 500.0
	laser_instance.knockback_force = 10.0
	add_child(laser_instance)
	laser_instance.setup(self)

func stop_shooting():
	if laser_instance:
		laser_instance.stop()
		laser_instance = null

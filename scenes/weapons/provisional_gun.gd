extends Node2D

@onready var bullet_scene = preload("res://scenes/weapons/player_bullet.tscn")
@onready var cooldown_timer = $ShootCooldown

func shoot():
	if cooldown_timer.is_stopped() == false:
		return
		
	self.get_node("AnimatedSprite2D").play("attacking")
	
	var bullet = bullet_scene.instantiate()
	
	bullet.global_position = global_position
	bullet.bullet_direction = (global_position - get_global_mouse_position()).normalized()

	get_tree().current_scene.add_child(bullet)
	
	cooldown_timer.start()

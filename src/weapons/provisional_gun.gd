extends Node2D

@onready var bullet_scene = preload("res://scenes/weapons/bullets/player_bullet.tscn")
@onready var cooldown_timer = $ShootCooldown
@export var damage : float = 1.5

func shoot():
	if cooldown_timer.is_stopped() == false:
		return
		
	self.get_node("AnimatedSprite2D").play("attacking")
	
	var bullet = bullet_scene.instantiate()
	bullet.area_entered.connect(_on_hitbox_enter)
	
	bullet.global_position = global_position
	bullet.bullet_direction = (global_position - get_global_mouse_position()).normalized()

	get_tree().current_scene.add_child(bullet)
	
	cooldown_timer.start()


func _on_hitbox_enter(area):
	if area.is_in_group("enemy"):
		var enemy_node = area.get_parent()
		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)
		

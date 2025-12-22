extends Weapon

@onready var bullet_scene = preload("res://scenes/bullets/player_bullet.tscn")

func _ready() -> void:
	id=2
	damage = 1.5
	knockback_force = 75.0
	lifetime=3.0
	speed = 100.0

func shoot():
	if cooldown_timer.is_stopped() == false:
		return
		
	self.get_node("AnimatedSprite2D").play("attacking")
	
	var bullet = bullet_scene.instantiate()
	
	give_bullet_values(bullet)

	get_tree().current_scene.add_child(bullet)
	
	cooldown_timer.start()

func give_bullet_values(bullet: Bullet):
	bullet.global_position = global_position
	bullet.bullet_direction = (global_position - get_global_mouse_position()).normalized()
	bullet.damage = damage
	bullet.knockback_force = knockback_force
	bullet.lifetime = lifetime
	bullet.speed = speed

func _on_hitbox_enter(area):
	if area.is_in_group("enemy"):
		var enemy_node = area.get_parent()
		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)
		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)

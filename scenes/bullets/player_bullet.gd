extends Bullet



func init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_bullet_owner, _extras: Dictionary = {}) -> void:
	modifiers = ["piercing"]
	self.global_position = new_position
	self.bullet_direction = new_forward
	self.damage = new_damage
	self.knockback_force = new_knockback_force
	self.lifetime = new_lifetime
	self.speed = new_speed
	self.bullet_owner = new_bullet_owner
	
	_update_sprite_rotation()

func _update_sprite_rotation() -> void:
	if bullet_direction == Vector2.ZERO:
		return
	self.rotation = bullet_direction.angle()

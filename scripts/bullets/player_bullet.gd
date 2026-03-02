extends Bullet

func init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_owner) -> void:
	self.global_position = new_position
	self.bullet_direction = new_forward
	self.damage = new_damage
	self.knockback_force = new_knockback_force
	self.lifetime = new_lifetime
	self.speed = new_speed
	self.bullet_owner = new_owner

func test():
	pass

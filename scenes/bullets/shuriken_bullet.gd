extends Bullet

@onready var sprite: Sprite2D

func _ready():
	super._ready()
	speed_rotation = 700.0
	sprite = $Visual/Sprite2D

func init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_bullet_owner, _extras: Dictionary = {}) -> void:
	self.global_position = new_position
	self.bullet_direction = new_forward
	self.damage = new_damage
	self.knockback_force = new_knockback_force
	self.lifetime = new_lifetime
	self.speed = new_speed
	self.bullet_owner = new_bullet_owner

func _process(delta: float):
	global_position -= bullet_direction * speed * delta
	rotation_degrees += speed_rotation * delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()

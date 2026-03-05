extends Bullet

@onready var sprite: Sprite2D
var paint_color : Color = Color(0.156, 0.333, 0.603, 1.0)

func _ready():
	super._ready()
	speed_rotation = 500.0
	sprite = $Visual/Sprite2D

func init(new_forward, new_position, new_damage, new_knockback_force, new_lifetime, new_speed, new_bullet_owner) -> void:
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
	
func _against_enemy(area):
	var enemy_node = area.get_parent()
	if enemy_node.has_method("change_color"):
		enemy_node.change_color(paint_color)
	super._against_enemy(area)

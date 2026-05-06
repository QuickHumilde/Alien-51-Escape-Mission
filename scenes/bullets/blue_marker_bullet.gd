extends Bullet

@export var slow_effect: SlowEffect
@onready var sprite: Sprite2D
var paint_color : Color = Color(0.156, 0.333, 0.603, 1.0)
var slow_strength: float = 50.0
var slow_duration: float = 1.0

func _ready():
	super._ready()
	speed_rotation = 500.0
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
	
func _against_enemy(area):
	var enemy_node = area.get_parent()
	await get_tree().create_timer(0.21).timeout
	if enemy_node != null:
		if enemy_node.has_method("apply_effect"):
			if slow_effect != null:
				var e: SlowEffect = slow_effect.duplicate(true)
				e.duration = slow_duration
				e.multiplier = clamp(1.0 - (slow_strength / 100.0), 0.05, 1.0)
				enemy_node.apply_effect(e)
		if enemy_node.has_method("change_color"):
			enemy_node.change_color(paint_color)

		

extends Weapon

@onready var bullet_scene = preload("res://scenes/bullets/blue_marker_bullet.tscn")

func _ready():
	id=4
	damage = 2
	knockback_force = 400.0
	self_knockback_force=0.0
	lifetime=500.0
	speed = 100.0
	setup_audio()
	
func shoot(player_damage: float, _player_lifetime: float):
	extra_damage = player_damage
	extra_lifetime = _player_lifetime
	
	if cooldown_timer.is_stopped() == false:
		return
	
	var bullet = bullet_scene.instantiate()
	
	give_bullet_values(bullet)

	get_tree().current_scene.add_child(bullet)
	
	var pitch := randf_range(0.9, 1.5)
	var volume := randf_range(-4.0, -2.5)
	
	give_knocback()
	
	play_sound("shoot", volume, pitch)
	
	cooldown_timer.start()

func give_bullet_values(bullet: Bullet):
	var forward := Vector2.LEFT.rotated(global_rotation)
	bullet.init(forward, global_position, damage+extra_damage, knockback_force, lifetime+extra_lifetime, speed, "player")

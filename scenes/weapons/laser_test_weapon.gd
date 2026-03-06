extends Weapon

@onready var bullet_scene = preload("res://scenes/bullets/laser_test.tscn")
@onready var cooldown = $ShootCooldown

func _ready() -> void:
	id=3
	damage = 0.01
	knockback_force = 0.0
	self_knockback_force=25.0
	lifetime=9000000.0
	speed = 100.0
	cooldown.wait_time = 0.01
	audio_player = $AudioStreamPlayer2D
	sounds = {
		"shoot": preload("res://assets/audio/sfx/weapons/pistol/PistolGunShoot.mp3"),
	}
	setup_audio()

func shoot(player_damage: float, player_lifetime: float):
	extra_damage = player_damage
	extra_lifetime = player_lifetime
	
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
	bullet.init(forward, global_position, damage+extra_damage, knockback_force, lifetime+extra_lifetime, 0.0, "player")

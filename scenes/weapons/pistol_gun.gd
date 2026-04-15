extends Weapon

@onready var bullet_scene = preload("res://scenes/bullets/player_bullet.tscn")
@onready var cooldown = $ShootCooldown
@onready var gunfire: CPUParticles2D = $Gunfire

func _ready() -> void:
	id=2
	damage = 1.5
	knockback_force = 75.0
	self_knockback_force= 50.0
	lifetime= 2.0
	speed = 100.0
	cooldown.wait_time = 1.0
	audio_player = $AudioStreamPlayer2D
	sounds = {
		"shoot": preload("res://assets/audio/sfx//PistolGunShoot_1.mp3"),
	}
	setup_audio()

func shoot(player_damage: float, player_lifetime: float):
	extra_damage = player_damage
	extra_lifetime = player_lifetime
	
	if cooldown_timer.is_stopped() == false:
		return
		
	self.get_node("AnimatedSprite2D").play("attacking")
	
	var bullet = bullet_scene.instantiate()
	
	give_bullet_values(bullet)

	gunfire.play_one_shot()
	
	get_tree().current_scene.add_child(bullet)
	
	var pitch := randf_range(0.9, 1.5)
	var volume := randf_range(-4.0, -2.5)
	
	give_knocback()
	
	play_sound("shoot", volume, pitch)
	
	cooldown_timer.start()

func give_bullet_values(bullet: Bullet):
	var forward = Vector2.RIGHT.rotated(global_rotation)
	bullet.init(forward, global_position, damage+extra_damage, knockback_force, lifetime+extra_lifetime, speed, "player")

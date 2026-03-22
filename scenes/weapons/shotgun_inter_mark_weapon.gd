extends Weapon

@onready var bullet_scene: PackedScene = preload("res://scenes/bullets/shotgun_bullet.tscn")
@onready var cooldown: Timer = $ShootCooldown
@onready var barrel: Node2D = $Barrel
var pellets: int = 4

func _ready() -> void:
	id=3
	damage = 1.5
	knockback_force = 75.0
	self_knockback_force= 50.0
	lifetime= 0.5
	speed = 85.0
	cooldown.wait_time = 1.0
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
		
	self.get_node("AnimatedSprite2D").play("attacking")
	
	for i in range(pellets):
		var bullet = bullet_scene.instantiate()
		var offset = Vector2(randf_range(0.5, 0.75), randf_range(-0.5, 0.75))
		give_bullet_values(bullet, offset)
		get_tree().current_scene.add_child(bullet)
	
	var pitch := randf_range(0.9, 1.5)
	var volume := randf_range(-4.0, -2.5)
	
	give_knocback()
	
	play_sound("shoot", volume, pitch)
	
	cooldown_timer.start()

func give_bullet_values(bullet: Bullet, offset: Vector2) -> void:
	var forward := Vector2.RIGHT.rotated(global_rotation)
	var dir := (forward + offset).normalized()
	bullet.init(dir, barrel.global_position, damage + extra_damage, knockback_force, lifetime + extra_lifetime, speed, "player")

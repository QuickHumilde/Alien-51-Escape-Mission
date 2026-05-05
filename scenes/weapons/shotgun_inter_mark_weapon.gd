extends Weapon

@onready var bullet_scene: PackedScene = preload("res://scenes/bullets/shotgun_bullet.tscn")
@onready var cooldown: Timer = $ShootCooldown
@onready var barrel: Node2D = $Barrel
@onready var gunfire: CPUParticles2D = $Gunfire
var min_pellets: int = 4
var max_pellets: int = 6

func _ready() -> void:
	id = 7
	damage = 1.5
	knockback_force = 100.0
	self_knockback_force= 150.0
	lifetime= 0.30
	speed = 85.0
	cooldown.wait_time = 1.5
	audio_player = $AudioStreamPlayer2D
	sounds = {
		"shoot": preload("res://assets/audio/sfx/ShotgunShoot_1.mp3"),
	}
	setup_audio()

func shoot(player_damage: float, player_lifetime: float):
	extra_damage = player_damage
	extra_lifetime = player_lifetime
	
	if cooldown_timer.is_stopped() == false:
		return
		
	self.get_node("AnimatedSprite2D").play("attacking")
	
	var random_pellets: int = randi_range(min_pellets, max_pellets - 1)
	for i in range(random_pellets):
		var bullet = bullet_scene.instantiate()
		var offset = Vector2(randf_range(-0.5, 0.85), randf_range(-0.5, 0.85))
		give_bullet_values(bullet, offset)
		get_tree().current_scene.add_child(bullet)
		bullet.sprite.scale.x = -1
	
	var pitch := randf_range(0.9, 1.5)
	var volume := randf_range(-4.0, -2.5)

	give_knocback()
	gunfire.play_one_shot()
	
	play_sound("shoot", volume, pitch)
	
	cooldown_timer.start()

func give_bullet_values(bullet: Bullet, offset: Vector2) -> void:
	var forward := Vector2.LEFT.rotated(global_rotation)
	var dir := (forward + offset.rotated(global_rotation)).normalized()
	bullet.init(dir, barrel.global_position, damage + extra_damage, knockback_force, lifetime + extra_lifetime, speed, "player")

func give_knocback():
	var body = get_parent().get_parent()
	var knockback_direction = (global_position - body.global_position).normalized()
	get_parent().get_parent().apply_knockback(knockback_direction, self_knockback_force)

extends Weapon

@onready var bullet_scene = preload("res://scenes/bullets/player_bullet.tscn")
@onready var cooldown = $ShootCooldown
@onready var audio_player = $AudioStreamPlayer2D

var sounds := {
	"shoot": preload("res://assets/audio/sfx/weapons/pistol/PistolGunShoot.mp3"),
}

func _ready() -> void:
	id=2
	damage = 1.5
	knockback_force = 75.0
	lifetime=3.0
	speed = 100.0
	cooldown.wait_time = 1.0
	setup_audio()

func shoot():
	if cooldown_timer.is_stopped() == false:
		return
		
	self.get_node("AnimatedSprite2D").play("attacking")
	
	var bullet = bullet_scene.instantiate()
	
	give_bullet_values(bullet)

	get_tree().current_scene.add_child(bullet)
	
	var pitch := randf_range(0.9, 1.5)
	var volume := randf_range(-4.0, -2.5)
	
	play_sound("shoot", volume, pitch)
	
	cooldown_timer.start()

func give_bullet_values(bullet: Bullet):
	var forward := Vector2.LEFT.rotated(global_rotation)
	bullet.init(forward, global_position, damage, knockback_force, lifetime, speed)

func _on_hitbox_enter(area):
	if area.is_in_group("enemy"):
		var enemy_node = area.get_parent()
		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)
		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)

func setup_audio():
	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "SFXPistolGun"
	audio_player.bus = "SFX"
	audio_player.max_polyphony = 16
	add_child(audio_player)

func play_sound(sound_name : String, volume_db: float = 0.0, pitch: float = 1.0):
	if not sounds.has(sound_name):
		push_warning("Sonido '" + sound_name + "' no encontrado.")
		return
	
	audio_player.stream = sounds[sound_name]
	audio_player.volume_db = volume_db
	audio_player.pitch_scale = pitch
	audio_player.play()

extends Weapon

@onready var bullet_scene = preload("res://scenes/bullets/shuriken_bullet.tscn")
#@onready var animation: AnimationPlayer = $Visual/AnimationPlayer
var bullets_quantity: int = 3

func _ready():
	id=3
	damage = 1
	knockback_force = 100.0
	self_knockback_force=10.0
	lifetime=1.0
	speed = 200.0
	sounds = {
		"shoot" : preload("res://assets/audio/sfx/BlueMarkerThrow.mp3")
	}
	setup_audio()
	
func shoot(player_damage: float, _player_lifetime: float):
	extra_damage = player_damage
	extra_lifetime = _player_lifetime
	
	if cooldown_timer.is_stopped() == false:
		return
	
	var spread_deg: float = 30.0
	var spread: float = deg_to_rad(spread_deg)

	var angles: Array = [
		global_rotation - spread,
		global_rotation,
		global_rotation + spread
	]

	for angle in angles:
		var bullet = bullet_scene.instantiate()
		give_bullet_values(bullet, angle)
		get_tree().current_scene.add_child(bullet)
		bullet.sprite.scale.x = -1

	var pitch: float = randf_range(0.9, 1.5)
	give_knocback()
	
	play_sound("shoot", 0, pitch)
	
	cooldown_timer.start()
	
func give_bullet_values(bullet: Bullet, angle: float) -> void:
	var dir: Vector2 = Vector2.LEFT.rotated(angle)
	bullet.init(dir, global_position, damage + extra_damage, knockback_force, lifetime + extra_lifetime, speed, "player")

func give_knocback():
	var body = get_parent().get_parent()
	var knockback_direction = (body.global_position - global_position).normalized()
	get_parent().get_parent().apply_knockback(knockback_direction, self_knockback_force)

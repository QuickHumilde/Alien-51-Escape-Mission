extends Weapon

@onready var melee_hitbox = $Hitbox
@onready var anim = $AnimationPlayer
@onready var cooldown = $ShootCooldown

func _ready():
	id = 1
	damage = 1
	knockback_force = 250.0
	sounds = {
		"shoot" : preload("res://assets/audio/sfx/player/uiuiuiADuque.mp3")
	}
	setup_audio()

func shoot(player_damage: float, _player_lifetime: float):
	extra_damage = player_damage
	if not $ShootCooldown.is_stopped():
		return
	
	if anim.current_animation != "attack":
		var pitch := randf_range(0.9, 1.5)
		var volume := randf_range(-4.0, -2.5)
		play_sound("shoot", volume, pitch)

	anim.play("attack")
	await anim.animation_finished
	$ShootCooldown.start()

func _on_hitbox_enter(area):
	if area.is_in_group("enemy"):
		var enemy_node = area.get_parent()

		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage+extra_damage)

		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)

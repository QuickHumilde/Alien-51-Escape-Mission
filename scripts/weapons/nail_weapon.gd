extends Weapon

@onready var anim = $Visual/AnimationPlayer
@onready var cooldown = $ShootCooldown
@onready var audio_player = $AudioStreamPlayer2D
@onready var melee_hitbox = $Hitbox

var sounds := {
	"shoot" : preload("res://assets/audio/sfx/player/uiuiuiADuque.mp3")
}

func _ready():
	melee_hitbox.area_entered.connect(_on_hitbox_enter)
	id = 4
	damage = 1
	knockback_force = 150.0
	self_knockback_force=125.0
	setup_audio()

func shoot():
	if not $ShootCooldown.is_stopped():
		return
		
	is_attacking = true
	
	if anim.current_animation != "attack":
		var pitch := randf_range(0.9, 1.5)
		var volume := randf_range(-4.0, -2.5)
		play_sound("shoot", volume, pitch)

	anim.play("attack")
	await anim.animation_finished
	is_attacking = false
	$ShootCooldown.start()

func _on_hitbox_enter(area):
	if area.is_in_group("enemy"):
		var enemy_node = area.get_parent()

		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)
			give_knocback()

		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)

func setup_audio():
	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "SFXArmWeapon"
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

@abstract
extends Node2D
class_name Weapon

@onready var player= get_tree()
@onready var cooldown_timer = $ShootCooldown
@export var damage : float = 1.5
@export var extra_damage: float = 0.0
@export var extra_lifetime: float = 0.0
@export var knockback_force : float = 50.0
@export var self_knockback_force : float = 50.0
@onready var audio_player : AudioStreamPlayer2D
var is_attacking : bool = false
var flip : bool = true
var id : int = 0
var lifetime: float = 0.0
var speed: float = 0.0
var sounds : Dictionary = {}

func give_knocback():
	var body = get_parent().get_parent()
	var knockback_direction = (body.global_position - global_position).normalized()
	get_parent().get_parent().apply_knockback(knockback_direction, self_knockback_force)

func destroy_weapon():
	var body = get_parent().get_parent()
	body.combat.remove_weapon(id)

func setup_audio():
	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "SFXWeapon"
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

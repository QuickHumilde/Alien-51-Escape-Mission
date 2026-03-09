@abstract
extends CharacterBody2D
class_name Enemy

@export var id : int
@export var speed : float = 50.0
@export var health : float = 3.0
@export var contact_damage: float = 0.0
@onready var player: CharacterBody2D = get_tree().current_scene.get_node("Player")
@onready var visuals : Node2D = $Visual
@onready var sfx_enemy: AudioStreamPlayer2D
var knockback: Vector2
var color_time : float = 3.0
var color_time_cooldown : float = 9.0
@export var knockback_force : float = 0.0
var knockback_time : float = 0.0
var knockback_resistance : float =0.0
var can_change_color : bool = true
var sounds  : Dictionary = {
	"damage": preload("res://assets/audio/sfx/enemies/stalkerenemy/StalkerDamage.mp3")
}
var damage_ticks : int = 0

func _ready():
	setup_audio()

func apply_knockback(dir: Vector2, force: float = 500.0, duration: float = 0.2):
	if knockback_resistance < force:
		knockback = dir * (force - knockback_resistance)
		knockback_time = duration

func take_damage(damage : float):
	damage_ticks += 1 
	visuals.modulate = Color(1.0, 0.0, 0.0, 1.0)
	health -= damage
	await get_tree().create_timer(0.2).timeout
	damage_ticks -= 1 

	if damage_ticks <= 0:
		visuals.modulate = Color(1,1,1)

	if health <= 0:
		die()
	else:
		_on_damage()


func die():
	queue_free()

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		do_damage(body)

func do_damage(body):
	var knockback_direction = (body.global_position - global_position).normalized()
	if body.is_in_group("player"):
		if is_player_damagable(body):
			body.apply_knockback(knockback_direction, knockback_force)
			body.take_damage(contact_damage)

func _get_detector():
	$Detector.body_entered.connect(_on_area_2d_body_entered)
  
func get_damage():
	return contact_damage

func is_player_damagable(body: Character):
	return body.is_player_damagable()

func change_color(new_color: Color):
	if can_change_color:
		visuals.modulate = new_color
		can_change_color=false
		await get_tree().create_timer(color_time).timeout
		visuals.modulate = Color(1,1,1)
		await get_tree().create_timer(color_time_cooldown).timeout
		can_change_color = true

func setup_audio():
	sfx_enemy = AudioStreamPlayer2D.new()
	sfx_enemy.name = "SFXEnemy"
	sfx_enemy.bus = "SFX"
	sfx_enemy.max_polyphony = 16
	add_child(sfx_enemy)

func play_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0):
	sfx_enemy.stream = sounds[sound_name]
	sfx_enemy.volume_db = volume_db
	sfx_enemy.pitch_scale = pitch
	sfx_enemy.play()

@abstract func _on_damage()

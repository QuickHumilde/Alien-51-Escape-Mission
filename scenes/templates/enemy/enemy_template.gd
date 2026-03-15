@abstract
extends CharacterBody2D
class_name Enemy

@export var id : int
@export var speed : float = 50.0
@export var health : float = 3.0
@export var contact_damage: float = 0.0
@export var spawn_freeze_time: float = 0.5
@export var knockback_force : float = 0.0

@onready var player: CharacterBody2D = get_tree().current_scene.get_node("Player")
@onready var visuals : Node2D = $Visual
@onready var sfx_enemy: AudioStreamPlayer2D

var _frozen: bool = false
var knockback: Vector2
var knockback_time : float = 0.0
var knockback_resistance : float = 0.0
var can_change_color : bool = true
var color_time : float = 3.0
var color_time_cooldown : float = 9.0
var damage_ticks : int = 0

var sounds  : Dictionary = {
	"damage": preload("res://assets/audio/sfx/enemies/stalkerenemy/StalkerDamage.mp3")
}

func _ready() -> void:
	setup_audio()
	if spawn_freeze_time > 0.0:
		freeze_for(spawn_freeze_time)

func freeze_for(seconds: float) -> void:
	_frozen = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(seconds).timeout
	_frozen = false

func is_frozen() -> bool:
	return _frozen

func process_frozen() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

func apply_knockback(dir: Vector2, force: float = 500.0, duration: float = 0.2) -> void:
	if knockback_resistance < force:
		knockback = dir * (force - knockback_resistance)
		knockback_time = duration

func take_damage(damage : float) -> void:
	damage_ticks += 1
	visuals.modulate = Color(1.0, 0.0, 0.0, 1.0)
	health -= damage
	await get_tree().create_timer(0.2).timeout
	damage_ticks -= 1

	if damage_ticks <= 0:
		visuals.modulate = Color(1, 1, 1)

	if health <= 0:
		die()
	else:
		_on_damage()

func die() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Node) -> void:
	if _frozen:
		return
	if body.is_in_group("player"):
		do_damage(body)

func do_damage(body: Node) -> void:
	var knockback_direction = (body.global_position - global_position).normalized()
	if body.is_in_group("player"):
		if is_player_damagable(body):
			body.apply_knockback(knockback_direction, knockback_force)
			body.take_damage(contact_damage)

func _get_detector() -> void:
	$Detector.body_entered.connect(_on_area_2d_body_entered)

func get_damage() -> float:
	return contact_damage

func is_player_damagable(body: Character) -> bool:
	return body.is_player_damagable()

func change_color(new_color: Color) -> void:
	if can_change_color:
		visuals.modulate = new_color
		can_change_color = false
		await get_tree().create_timer(color_time).timeout
		visuals.modulate = Color(1, 1, 1)
		await get_tree().create_timer(color_time_cooldown).timeout
		can_change_color = true

func setup_audio() -> void:
	sfx_enemy = AudioStreamPlayer2D.new()
	sfx_enemy.name = "SFXEnemy"
	sfx_enemy.bus = "SFX"
	sfx_enemy.max_polyphony = 16
	add_child(sfx_enemy)

func play_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	sfx_enemy.stream = sounds[sound_name]
	sfx_enemy.volume_db = volume_db
	sfx_enemy.pitch_scale = pitch
	sfx_enemy.play()

@abstract func _on_damage() -> void

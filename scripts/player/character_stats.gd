extends Node
class_name CharacterStats

@export_category("Player Character")
@export_group("Stats")
@export var max_health: float = 5
@export var health: float = 5
@export var extra_health: float = 0
@export var speed: float = 100.0
@export var size: float = 1.0
@export var extra_damage: float = 1.0
@export var invulnerability_time: float = 1.0
@onready var player_audio: CharacterAudio
@onready var player_animation: CharacterAnimation
static var abilities := {}
var sprite: AnimatedSprite2D
var player_collision_detector: CollisionShape2D
var player_hitbox: CollisionShape2D

func init(cSprite: AnimatedSprite2D, audio:CharacterAudio, animation: CharacterAnimation, detector: CollisionShape2D, hitbox: CollisionShape2D) -> void:
	sprite= cSprite
	player_audio = audio
	player_animation = animation
	player_collision_detector = detector
	player_hitbox=hitbox
	pass
	
func _ready() -> void:
	Signals.health_changed.emit(health, max_health, extra_health)

func take_damage(amount: float):
	
	if (extra_health <= 0.0):
		health -= amount
		
	elif(extra_health>=amount):
		extra_health-=amount
	else:
		var rest = amount-extra_health
		extra_health=0.0
		health -= rest
	
	_emit_health_changed_signal()
	
	if health <= 0.0:
		die()

func heal(amount: float):
	health = min(health + amount, max_health)
	_emit_health_changed_signal()

func increase_max_health(amount: float):
	max_health += amount
	
	_emit_health_changed_signal()

func increase_extra_health(amount:float):
	extra_health+=amount
	
	_emit_health_changed_signal()

func modify_speed(amount: float):
	speed += amount

func modify_size(amount: float):
	size += amount
	sprite.scale = Vector2(size, size)
	player_collision_detector.scale = Vector2(size, size)
	player_hitbox.scale = Vector2(size, size)

func unlock_ability(ability_name: String):
	abilities[ability_name] = true
	
func has_ability(ability_name: String) -> bool:
	return abilities.has(ability_name)

func _emit_health_changed_signal():
	Signals.health_changed.emit(health, max_health, extra_health)

func die():
	player_audio.play_death()
	player_animation.player_dying()
	Signals.player_death.emit()

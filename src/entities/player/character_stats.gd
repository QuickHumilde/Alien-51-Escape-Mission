extends Node
class_name CharacterStats

var sprite: AnimatedSprite2D
@export var max_health: float = 5
@export var health: float = 5
@export var extra_health: float = 0
@export var speed: float = 100.0
@export var size: float = 1.0
@export var extra_damage: float = 1.0
@onready var player_audio: CharacterAudio
@onready var player_animation: CharacterAnimation
static var abilities := {}

signal died
signal health_changed(current_health: float, max_health: float)

func init(audio:CharacterAudio, animation: CharacterAnimation) -> void:
	player_audio = audio
	player_animation = animation
	pass
	
func _ready() -> void:
	health_changed.emit(health, max_health)

func take_damage(amount: float):
	
	if (extra_health <= 0.0):
		health -= amount
		
	elif(extra_health>=amount):
		extra_health-=amount
	else:
		var rest = amount-extra_health
		extra_health=0.0
		health -= rest
	
	health_changed.emit(health, max_health, extra_health)
	
	if health <= 0.0:
		died.emit()
		queue_free()

func heal(amount: float):
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health, extra_health)

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
	get_parent().get_parent().sprite.scale = Vector2.ONE * size

func unlock_ability(ability_name: String):
	abilities[ability_name] = true
	
func has_ability(ability_name: String) -> bool:
	return abilities.has(ability_name)

func _emit_health_changed_signal():
	health_changed.emit(health, max_health, extra_health)

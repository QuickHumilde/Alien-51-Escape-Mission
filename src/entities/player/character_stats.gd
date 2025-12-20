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
var abilities := {}

func init(audio:CharacterAudio) -> void:
	player_audio = audio
	pass

func take_damage(amount: float):
	player_audio.play_damage()
	
	sprite.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1,1,1)
	
	if (extra_health <= 0.0):
		health -= amount
		
	elif(extra_health>=amount):
		extra_health-=amount
	else:
		var rest = amount-extra_health
		extra_health=0.0
		health -= amount
	
	if health <= 0.0:
		queue_free()

func heal(amount: float):
	health = min(health + amount, max_health)

func increase_max_health(amount: float):
	max_health += amount
	health = max_health

func increase_extra_health(amount:float):
	extra_health=+amount

func modify_speed(amount: float):
	speed += amount

func modify_size(amount: float):
	size += amount
	get_parent().get_parent().sprite.scale = Vector2.ONE * size

func unlock_ability(ability_name: String):
	abilities[ability_name] = true
	
func has_ability(ability_name: String) -> bool:
	return abilities.has(ability_name)

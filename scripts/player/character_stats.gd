extends Node
class_name CharacterStats

@export_category("Player Character")
@export_group("Stats")
@export var max_health: float = 5
@export var health: float = 5
@export var extra_health: float = 0
@export var speed: float = 75.0
@export var size: float = 1.0
@export var extra_damage: float = 0.0
@export var extra_lifetime: float = 0.0
@export var invulnerability_time: float = 1.0
@export var is_flying: bool = false
@export var modifiers: Array = []
@export var revives: int = 0

@onready var player_audio: CharacterAudio
@onready var player_animation: CharacterAnimation
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
	Signals.health_changed.emit(health, max_health, extra_health, revives)

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
	if size <=	 1:
		player_hitbox.scale = Vector2(size, size)
	else:
		Vector2(1, 1)

func modify_revives(amount: float):
	revives += int(amount)
	_emit_health_changed_signal()

func player_fly(fly : bool):
	if fly and !is_flying:
		is_flying=true
		player_animation.is_flying=true
	elif !fly and is_flying:
		is_flying=false

func get_speed() -> float:
	var value = speed
	for mod in modifiers:
		if mod.has_method("get_bonus"):
			value += mod.get_bonus("speed", self)
	return value

func get_damage() -> float:
	var value = extra_damage
	for mod in modifiers:
		if mod.has_method("get_bonus"):
			value += mod.get_bonus("damage", self)
	return value

func get_size() -> float:
	var value = size
	for mod in modifiers:
		if mod.has_method("get_bonus"):
			value += mod.get_bonus("size", self)
	return value

func get_max_health() -> float:
	var value = max_health
	for mod in modifiers:
		if mod.has_method("get_bonus"):
			value += mod.get_bonus("max_health", self)
	return value

func get_lifetime() -> float:
	var value = extra_lifetime
	for mod in modifiers:
		if mod.has_method("get_bonus"):
			value += mod.get_bonus("lifetime", self)
	return value

func _emit_health_changed_signal():
	Signals.health_changed.emit(health, max_health, extra_health, revives)

func die():
	player_audio.play_death()
	player_animation.player_dying(revives)
	Signals.player_death.emit()
	
	if (revives > 0):
		await player_animation.sprite.animation_finished
		Signals.player_revive.emit()
		revives -= 1
		heal(2)

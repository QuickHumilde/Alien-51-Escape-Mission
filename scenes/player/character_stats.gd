extends Node
class_name CharacterStats

signal stats_changed

@export var max_health: float = 5.0
@export var health: float = 0.0
@export var extra_health: float = 0
@export var speed: float = 75.0
@export var size: float = 1.0
@export var extra_damage: float = 0.0
@export var extra_lifetime: float = 0.0
@export var invulnerability_time: float = 1.0
@export var is_flying: bool = false
@export var revives: int = 0

@onready var player_inventory: PlayerInventory
@onready var player_audio: CharacterAudio
@onready var player_animation: CharacterAnimation
@onready var sprite: AnimatedSprite2D
@onready var player_collision_detector: CollisionShape2D
@onready var player_hitbox: CollisionShape2D
@onready var player_tramp_collision_detector: CollisionShape2D
@onready var visuals: Node2D

var stats_variated: bool = true

var cached_speed: float
var cached_damage: float
var cached_size: float
var cached_max_health: float
var cached_lifetime: float
var cached_invulnerability: float

func init(cSprite: AnimatedSprite2D, audio:CharacterAudio, animation: CharacterAnimation, detector: CollisionShape2D, hitbox: CollisionShape2D, cVisuals: Node2D, tramp_hitbox: CollisionShape2D, inventory: PlayerInventory) -> void:
	health = max_health
	sprite = cSprite
	player_audio = audio
	player_animation = animation
	player_collision_detector = detector
	player_hitbox = hitbox
	visuals = cVisuals
	player_tramp_collision_detector = tramp_hitbox
	player_inventory = inventory
	stats_variated = true

func _ready() -> void:
	Signals.health_changed.emit(health, max_health, extra_health, revives)

func recalc_stats():
	cached_speed = speed
	cached_damage = extra_damage
	cached_size = size
	cached_max_health = max_health
	cached_lifetime = extra_lifetime
	cached_invulnerability = invulnerability_time

	for mod in player_inventory.get_modifiers():
		if mod.has_method("get_bonus"):
			cached_speed += mod.get_bonus("speed", self)
			cached_damage += mod.get_bonus("damage", self)
			cached_size += mod.get_bonus("size", self)
			cached_max_health += mod.get_bonus("max_health", self)
			cached_lifetime += mod.get_bonus("lifetime", self)
			cached_invulnerability += mod.get_bonus("invulnerability_time", self)

	if cached_invulnerability < 0.05:
		cached_invulnerability = 0.05
	
	if cached_size < 0.1:
		cached_size = 0.1
		
	if cached_damage < 0:
		cached_damage = 0
	
	_apply_size_visual(cached_size)
	stats_variated = false
	emit_signal("stats_changed")

func get_speed() -> float:
	if stats_variated:
		recalc_stats()
	return cached_speed

func get_damage() -> float:
	if stats_variated:
		recalc_stats()
	return cached_damage

func get_size() -> float:
	if stats_variated:
		recalc_stats()
	return cached_size

func get_max_health() -> float:
	if stats_variated:
		recalc_stats()
	return cached_max_health

func get_lifetime() -> float:
	if stats_variated:
		recalc_stats()
	return cached_lifetime

func get_invulnerability_time() -> float:
	if stats_variated:
		recalc_stats()
	return cached_invulnerability

func _invalidate_stats():
	stats_variated = true

func take_damage(amount: float):
	if extra_health <= 0.0:
		health -= amount
	elif extra_health >= amount:
		extra_health -= amount
	else:
		var rest = amount - extra_health
		extra_health = 0.0
		health -= rest

	_emit_health_changed_signal()
	_invalidate_stats()

	if health <= 0.0:
		die()

func heal(amount: float) -> bool:
	var healed := false

	if amount > 0 and health < max_health:
		var before := health
		health = min(health + amount, max_health)

		if health > before:
			_emit_health_changed_signal()
			healed = true
			_invalidate_stats()

	return healed

func increase_max_health(amount: float):
	max_health += amount
	_emit_health_changed_signal()
	_invalidate_stats()

func increase_extra_health(amount: float):
	extra_health += amount
	_emit_health_changed_signal()
	_invalidate_stats()

func modify_speed(amount: float):
	speed += amount
	_invalidate_stats()

func modify_size(amount: float):
	size += amount
	_invalidate_stats()

func modify_revives(amount: float):
	revives += int(amount)
	_emit_health_changed_signal()

func _emit_health_changed_signal():
	Signals.health_changed.emit(health, max_health, extra_health, revives)

func die():
	player_audio.play_death()
	player_animation.player_dying(revives)
	Signals.player_death.emit()

	if revives > 0:
		revive()

func revive():
	await player_animation.sprite.animation_finished
	Signals.player_revive.emit()
	revives -= 1

	if max_health >= 3:
		max_health -= 1

	health = 2
	Signals.health_changed.emit(health, max_health, extra_health, revives)
	_invalidate_stats()

func is_player_full_healed():
	return health == max_health

func _apply_size_visual(final_size: float):
	visuals.scale = Vector2(final_size, final_size)
	player_collision_detector.scale = Vector2(final_size, final_size)
	player_tramp_collision_detector.scale = Vector2(final_size, final_size)

	if final_size <= 1:
		player_hitbox.scale = Vector2(final_size, final_size)

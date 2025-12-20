extends CharacterBody2D
class_name Character

@onready var sprite = $AnimatedSprite2D
@onready var movement = $Logic/Movement
@onready var animation = $Logic/Animation
@onready var combat = $Logic/Combat
@onready var stats = $Logic/Stats
@onready var items = $Logic/Items
@onready var audio = $Logic/Audio
@onready var damage_timer = $Logic/DamageTimer
@onready var hitbox_detector : CollisionShape2D = $Detector/HitboxDetector
@onready var detector_area : Area2D = $Detector
@onready var weapon_holder = $WeaponHolder

func _ready():
	combat.init(weapon_holder, stats)
	items.init(self)
	movement.init(self)
	stats.init(audio, animation, hitbox_detector)
	animation.init(sprite, damage_timer)

func _process(_delta):
	movement.update(_delta, self)
	animation.update(self)
	combat.update(_delta, self)

func _physics_process(_delta):
	move_and_slide()

func take_damage(amount: float):
	if damage_timer.is_stopped():
		audio.play_damage()
		animation.player_taking_damage()
		stats.take_damage(amount)
		hitbox_detector.disabled = true
		damage_timer.start(damage_timer.wait_time)
		await damage_timer.timeout
		hitbox_detector.disabled = false
		
		await get_tree().create_timer(0.1).timeout
		
		check_overlapping_enemies()

func apply_knockback(dir: Vector2, force: float, duration: float = 0.2):
	if damage_timer.is_stopped():
		movement.apply_knockback(dir, force, duration)
	#else:
	#	movement.apply_knockback(dir, 75.0, duration)

func check_overlapping_enemies():
	var overlapping_bodies= detector_area.get_overlapping_areas()
	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			var damage = body.get_parent().do_damage(self)
			return

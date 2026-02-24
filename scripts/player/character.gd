extends CharacterBody2D
class_name Character

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var movement : CharacterMovement = $Logic/Movement
@onready var animation : CharacterAnimation = $Logic/Animation
@onready var combat : CharacterCombat = $Logic/Combat
@onready var stats : CharacterStats = $Logic/Stats
@onready var abilities : CharacterAbilities = $Logic/Abilities
@onready var items : CharacterItems = $Logic/Items
@onready var audio : CharacterAudio = $Logic/Audio
@onready var damage_timer = $Logic/DamageTimer
@onready var hitbox : CollisionShape2D = $Hitbox
@onready var hitbox_detector : CollisionShape2D = $Detector/HitboxDetector
@onready var detector_area : Area2D = $Detector
@onready var weapon_holder = $WeaponHolder

func _ready():
	Signals.player_death.connect(player_death)
	Signals.player_revive.connect(player_revive)
	combat.init(weapon_holder, stats)
	items.init(self)
	movement.init(self)
	abilities.init(self)
	stats.init(sprite, audio, animation, hitbox_detector, hitbox)
	animation.init(sprite, damage_timer)

func _process(_delta):
	movement.update(_delta, self)
	animation.update(self)
	combat.update(_delta, self)

func _physics_process(_delta):
	move_and_slide()

func take_damage(amount: float):
	if damage_timer.is_stopped() and !Signals.player_is_dead:
		audio.play_damage()
		stats.take_damage(amount)
		animation.player_taking_damage()
		damage_timer.start(stats.invulnerability_time)
		await damage_timer.timeout
		
		await get_tree().create_timer(0.25).timeout
		
		_check_overlapping_enemies()
		
func player_death():
	weapon_holder.hide()

func apply_knockback(dir: Vector2, force: float, duration: float = 0.2):
	if damage_timer.is_stopped():
		movement.apply_knockback(dir, force, duration)
	#else:
	#	movement.apply_knockback(dir, 75.0, duration)

func _check_overlapping_enemies():
	var overlapping_bodies= detector_area.get_overlapping_areas()
	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			body.get_parent().do_damage(self)
			return

func get_stats() -> CharacterStats:
	return stats

func set_flying():
	collision_mask &= ~(1 << 5)

func player_revive():
	weapon_holder.show()
	animation.player_taking_damage()
	damage_timer.start(stats.invulnerability_time)
	await damage_timer.timeout
	
	await get_tree().create_timer(0.25).timeout
	
	_check_overlapping_enemies()

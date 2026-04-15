extends CharacterBody2D
class_name Character

@onready var visuals : Node2D = $Visual
@onready var sprite : AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var movement : CharacterMovement = $Logic/Movement
@onready var animation : CharacterAnimation = $Logic/Animation
@onready var combat : CharacterCombat = $Logic/Combat
@onready var stats : CharacterStats = $Logic/Stats
@onready var abilities : CharacterAbilities = $Logic/Abilities
@onready var inventory: PlayerInventory = $Logic/Inventory
@onready var items : CharacterItems = $Logic/Items
@onready var audio : CharacterAudio = $Logic/Audio
@onready var damage_timer = $Logic/DamageTimer
@onready var hitbox : CollisionShape2D = $Hitbox
@onready var hitbox_detector : CollisionShape2D = $Detector/HitboxDetector
@onready var detector_area : Area2D = $Detector
@onready var tramp_detector_area : Area2D = $TrampDetector
@onready var tramp_detector_area_hitbox : CollisionShape2D = $TrampDetector/CollisionShape2D
@onready var weapon_holder = $WeaponHolder

func _ready():
	tramp_detector_area.area_entered.connect(_on_tramp_detector_area_entered)
	Signals.player_death.connect(player_death)
	Signals.player_revive.connect(player_revive)
	Signals.player_take_damage.connect(take_damage)
	combat.init(weapon_holder, stats)
	inventory.init(self)
	items.init(self)
	stats.init(sprite, audio, animation, hitbox_detector, hitbox, visuals, tramp_detector_area_hitbox, inventory)
	movement.init(self)
	abilities.init(self)
	animation.init(sprite, damage_timer, weapon_holder)

func _process(_delta):
	movement.update(_delta, self)
	animation.update(self)
	combat.update(_delta, self)
	
	# --------REMOVE---------------
	if Input.is_action_just_pressed("god_mode"):
		god_mode()
	if Input.is_action_just_pressed("open_doors"):
		Signals.room_cleared.emit()
	

func _physics_process(_delta):
	move_and_slide()

func take_damage(amount: float):
	if damage_timer.is_stopped() and !Signals.player_is_dead:
		var final_damage: float = amount
		for modifier in inventory.get_modifiers():
			if modifier.has_method("modify_incoming_damage"):
				final_damage = modifier.modify_incoming_damage(final_damage)

		for modifier in inventory.modifiers:
			if modifier.has_method("avoid_damage"):
				if modifier.avoid_damage():
					damage_timer.start(stats.get_invulnerability_time())
					await damage_timer.timeout
					_check_overlapping_enemies()
					_check_overlapping_tramps()
					return

		audio.play_damage()
		stats.take_damage(final_damage)
		animation.player_taking_damage()
		damage_timer.start(stats.get_invulnerability_time())
		await damage_timer.timeout
		await get_tree().create_timer(0.25).timeout
		_check_overlapping_enemies()
		_check_overlapping_tramps()

func player_death():
	if abilities and abilities.abilities.size() > 0:
		for ability in abilities.abilities:
			if is_instance_valid(ability):
				ability.queue_free()
	weapon_holder.hide()

func apply_knockback(dir: Vector2, force: float, duration: float = 0.2):
	if damage_timer.is_stopped():
		movement.apply_knockback(dir, force, duration)

func _on_tramp_detector_area_entered(body):
	if body.is_in_group("trap"):
		if body.has_method("do_damage"):
			body.do_damage(tramp_detector_area)

func _check_overlapping_enemies():
	var overlapping_bodies= detector_area.get_overlapping_areas()
	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			body.get_parent().do_damage(self)
			return
	
func _check_overlapping_tramps():
	var overlapping_tramps= tramp_detector_area.get_overlapping_areas()
	for body in overlapping_tramps:
		if body.is_in_group("trap"):
			body.do_damage(tramp_detector_area)
			return

func get_stats() -> CharacterStats:
	return stats

func set_flying():
	set_collision_mask_value(6, false)
	tramp_detector_area.set_collision_mask_value(2, false)

func player_revive():
	weapon_holder.show()
	animation.player_taking_damage()
	damage_timer.start(stats.get_invulnerability_time())
	await damage_timer.timeout
	
	await get_tree().create_timer(0.25).timeout
	
	_check_overlapping_enemies()

func change_player_damagable_timer(state: bool, _timer: float):
	if state and damage_timer.is_stopped():
		_check_overlapping_enemies()
	else:
		damage_timer.start(stats.get_invulnerability_time())
		await damage_timer.timeout
		_check_overlapping_enemies()

func is_player_damagable():
	return damage_timer.is_stopped()


# -------REMOVE-------------
func god_mode():
	if Input.is_action_just_pressed("god_mode"):
		print("eres dios")
		stats.extra_damage=99
		stats.invulnerability_time=99
		stats.speed+=100
		stats.extra_lifetime=100
		stats.max_health=99999
		stats.heal(999999999)

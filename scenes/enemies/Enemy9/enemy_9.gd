extends Enemy

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var detector: Area2D = $Detector
@onready var detector_shape: CollisionShape2D = $Detector/CollisionShape2D

@onready var bullet_scene = preload("res://scenes/bullets/spit_bullet.tscn")

enum State { SURFACE_CHASE, BURROW, UNDERGROUND_MOVE, EMERGE_WINDUP, ATTACK, RECOVER }
var state: State = State.SURFACE_CHASE
var _last_state: State = State.SURFACE_CHASE

enum AttackType { FAN3, CARDINAL4, BURST }
var _attack: AttackType = AttackType.FAN3

@export var surface_speed: float = 55.0
@export var underground_speed: float = 85.0

@export var stopping_distance: float = 160.0

@export var burrow_time: float = 0.5
@export var underground_move_time: float = 1.0
@export var emerge_windup_time: float = 0.45
@export var recover_time: float = 0.75

@export var attack_cooldown: float = 6.0
var _cd: float = 0.0

@export var damage: float = 1.0
@export var bullet_speed: float = 95.0
@export var bullet_lifetime: float = 2.0

@export var fan_spread_deg: float = 18.0

@export var burst_count: int = 4
@export var burst_gap: float = 0.12

@export var invulnerable_underground: bool = true
@export var disable_collision_underground: bool = true

var _t: float = 0.0
var _dash_target: Vector2 = Vector2.ZERO
var _facing: Vector2 = Vector2.RIGHT


func _ready() -> void:
	_get_detector()

	id = 9
	contact_damage = 2.0
	health = 20.0

	speed = surface_speed
	knockback_force = 600.0
	knockback_time = 0.0
	knockback_resistance = 100000000.0

	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 8.0

	_last_state = state
	super._ready()


func _physics_process(delta: float) -> void:
	if is_frozen():
		process_frozen()
		return
	if player == null:
		return

	_cd = maxf(_cd - delta, 0.0)
	_t += delta

	match state:
		State.SURFACE_CHASE:
			_process_surface_chase(delta)
		State.BURROW:
			_process_burrow(delta)
		State.UNDERGROUND_MOVE:
			_process_underground_move(delta)
		State.EMERGE_WINDUP:
			_process_emerge_windup(delta)
		State.ATTACK:
			_process_attack(delta)
		State.RECOVER:
			_process_recover(delta)

	if state != _last_state:
		_on_state_changed(_last_state, state)
		_last_state = state

	_update_animation()


func _on_state_changed(from_state: State, to_state: State) -> void:
	if to_state == State.BURROW:
		_set_underground(true)
	if to_state == State.ATTACK:
		_set_underground(false)


func _set_underground(value: bool) -> void:
	if is_instance_valid(sprite):
		sprite.visible = not value

	if disable_collision_underground and is_instance_valid(hitbox):
		hitbox.set_deferred("disabled", value)

	if is_instance_valid(detector):
		detector.set_deferred("monitoring", not value)
		detector.set_deferred("monitorable", not value)

	if is_instance_valid(detector_shape):
		detector_shape.set_deferred("disabled", value)

	contact_damage = 0.0 if value else 2.0

	if invulnerable_underground:
		set_meta("invulnerable", value)


func _process_surface_chase(delta: float) -> void:
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()

	if dist > 0.001:
		var dir := to_player / dist
		_facing = dir

		if dist > stopping_distance:
			agent.target_position = player.global_position
			var next_point := agent.get_next_path_position()
			velocity = (next_point - global_position).normalized() * surface_speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	if knockback_time > 0.0:
		velocity += knockback

	move_and_slide()
	_decay_knockback(delta)

	if _cd <= 0.0 and dist <= 500.0:
		state = State.BURROW
		_t = 0.0
		_cd = attack_cooldown
		velocity = Vector2.ZERO


func _process_burrow(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _t >= burrow_time:
		_pick_underground_target()
		state = State.UNDERGROUND_MOVE
		_t = 0.0


func _pick_underground_target() -> void:
	var base: Vector2 = player.global_position
	var offset = Vector2(randf_range(-140.0, 140.0), randf_range(-140.0, 140.0))

	_dash_target = base + offset
	agent.target_position = _dash_target


func _process_underground_move(_delta: float) -> void:
	agent.target_position = _dash_target
	var next_point := agent.get_next_path_position()

	var dir := (next_point - global_position)
	if dir.length() > 0.001:
		dir = dir.normalized()
		velocity = dir * underground_speed
		_facing = dir
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	var dist_to_target := global_position.distance_to(_dash_target)
	if dist_to_target <= 18.0 or _t >= underground_move_time:
		state = State.EMERGE_WINDUP
		_t = 0.0
		velocity = Vector2.ZERO


func _process_emerge_windup(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _t >= emerge_windup_time:
		_choose_attack()
		state = State.ATTACK
		_t = 0.0


func _choose_attack() -> void:
	var r := randf()
	if r < 0.40:
		_attack = AttackType.FAN3
	elif r < 0.75:
		_attack = AttackType.CARDINAL4
	else:
		_attack = AttackType.BURST


func _process_attack(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	match _attack:
		AttackType.FAN3:
			_attack_fan3()
		AttackType.CARDINAL4:
			_attack_cardinal4()
		AttackType.BURST:
			await _attack_burst()

	state = State.RECOVER
	_t = 0.0


func _attack_fan3() -> void:
	var to_player := (player.global_position - global_position)
	var base_dir := to_player.normalized() if to_player.length() > 0.001 else _facing

	var spread := deg_to_rad(fan_spread_deg)

	var dirs := [
		base_dir.rotated(-spread),
		base_dir,
		base_dir.rotated(spread)
	]

	for d in dirs:
		_spawn_bullet(d)


func _attack_cardinal4() -> void:
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for d in dirs:
		_spawn_bullet(d)


func _attack_burst() -> void:
	for i in burst_count:
		var to_player := (player.global_position - global_position)
		var dir := to_player.normalized() if to_player.length() > 0.001 else _facing
		_spawn_bullet(dir)
		await get_tree().create_timer(burst_gap).timeout


func _spawn_bullet(dir: Vector2) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.init(dir, global_position, damage, bullet_speed, bullet_lifetime, 100.0, "enemy")
	get_tree().current_scene.add_child(bullet)


func _process_recover(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _t >= recover_time:
		state = State.SURFACE_CHASE
		_t = 0.0


func _decay_knockback(delta: float) -> void:
	if knockback_time > 0.0:
		knockback_time -= delta
		knockback = knockback.move_toward(
			Vector2.ZERO,
			(knockback.length() / max(knockback_time, 0.01)) * delta
		)
	else:
		knockback = Vector2.ZERO


func _on_damage() -> void:
	if invulnerable_underground and get_meta("invulnerable", false) == true:
		return
	pass


func _update_animation() -> void:
	if state == State.BURROW or state == State.UNDERGROUND_MOVE or state == State.EMERGE_WINDUP:
		return

	_play_walk_4dir(_facing)


func _play_walk_4dir(dir: Vector2) -> void:
	if not is_instance_valid(sprite):
		return
	if dir.length_squared() < 0.0001:
		return

	var anim := ""
	var flip_h := false

	if absf(dir.x) > absf(dir.y):
		anim = "walk_left"
		flip_h = dir.x > 0.0
	else:
		anim = "walk_front" if dir.y > 0.0 else "walk_back"
		flip_h = false

	if sprite.animation != anim:
		sprite.play(anim)
	sprite.flip_h = flip_h

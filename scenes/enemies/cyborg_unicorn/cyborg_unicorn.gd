extends Enemy

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var charge_ray: RayCast2D = $ChargeRay
@onready var dash_particles: GPUParticles2D = $Visual/DashParticles

enum State { CHASE, WINDUP, DASH, RECOVER }
var state: State = State.CHASE
var _last_state: State = State.CHASE

@export var chase_speed: float = 45.0
@export var dash_speed: float = 220.0

@export var dash_range: float = 220.0
@export var dash_cooldown: float = 2.5
@export var windup_time: float = 0.35
@export var recover_time: float = 0.6
@export var dash_particles_offset: float = 10.0

@export var fov_cos: float = 0.75
@export var use_raycast_los: bool = true
@export var ray_extra_length: float = 10.0

@export var dash_particles_continuous: bool = true

var _dash_dir: Vector2 = Vector2.RIGHT
var _dash_cd: float = 0.0
var _state_t: float = 0.0
var _facing: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_get_detector()

	id = 8
	contact_damage = 2.0
	health = 30.0

	speed = chase_speed
	knockback_force = 700.0
	knockback_time = 0.0
	knockback_resistance = 0.2

	if charge_ray != null:
		charge_ray.add_exception(self)
		charge_ray.enabled = true

	if is_instance_valid(dash_particles):
		dash_particles.emitting = false

	_last_state = state
	super._ready()

func _physics_process(delta: float) -> void:
	if is_frozen():
		process_frozen()
		return
	if player == null:
		return

	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_state_t += delta

	match state:
		State.CHASE:
			_process_chase(delta)
		State.WINDUP:
			_process_windup(delta)
		State.DASH:
			_process_dash(delta)
		State.RECOVER:
			_process_recover(delta)

	if state != _last_state:
		_on_state_changed(_last_state, state)
		_last_state = state

	_update_animation()

func _on_state_changed(from_state: State, to_state: State) -> void:
	if to_state == State.DASH:
		_fx_dash_start()
	if from_state == State.DASH and to_state != State.DASH:
		_fx_dash_end()

func _fx_dash_start() -> void:
	if not is_instance_valid(dash_particles):
		return

	_orient_dash_particles(_dash_dir)

	if dash_particles_continuous:
		dash_particles.emitting = true
	else:
		dash_particles.emitting = false
		dash_particles.restart()
		dash_particles.emitting = true

func _fx_dash_end() -> void:
	if not is_instance_valid(dash_particles):
		return
	dash_particles.emitting = false

func _orient_dash_particles(dir: Vector2) -> void:
	if not is_instance_valid(dash_particles):
		return
	if dir.length_squared() < 0.0001:
		return

	var back_dir: Vector2= -dir.normalized()

	dash_particles.rotation = back_dir.angle()

	dash_particles.position = back_dir * dash_particles_offset

func _process_chase(_delta: float) -> void:
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()

	if dist > 0.001:
		var dir := to_player / dist
		velocity = dir * chase_speed
		_facing = dir
	else:
		velocity = Vector2.ZERO

	if _dash_cd <= 0.0 and dist <= dash_range:
		if _player_in_front(to_player) and _has_line_of_sight_to_player(to_player, dist):
			state = State.WINDUP
			_state_t = 0.0
			velocity = Vector2.ZERO
			move_and_slide()
			return

	if knockback_time > 0.0:
		velocity += knockback

	move_and_slide()
	_decay_knockback(_delta)

func _process_windup(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _state_t >= windup_time:
		var dir := (player.global_position - global_position)
		_dash_dir = dir.normalized() if dir.length() > 0.001 else _facing
		state = State.DASH
		_state_t = 0.0

func _process_dash(_delta: float) -> void:
	velocity = _dash_dir * dash_speed
	move_and_slide()

	if get_slide_collision_count() > 0 or is_on_wall():
		state = State.RECOVER
		_state_t = 0.0
		_dash_cd = dash_cooldown
		velocity = Vector2.ZERO

func _process_recover(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _state_t >= recover_time:
		state = State.CHASE
		_state_t = 0.0

func _player_in_front(to_player: Vector2) -> bool:
	if to_player.length_squared() < 0.0001:
		return true
	var dir := to_player.normalized()
	var facing := _facing
	if facing.length_squared() < 0.0001:
		facing = dir
	return facing.dot(dir) >= fov_cos

func _has_line_of_sight_to_player(to_player: Vector2, dist: float) -> bool:
	if not use_raycast_los:
		return true
	if charge_ray == null:
		return true
	if dist <= 0.001:
		return true

	var dir := to_player / dist
	charge_ray.target_position = dir * (minf(dist, dash_range) + ray_extra_length)
	charge_ray.force_raycast_update()

	if not charge_ray.is_colliding():
		return true

	return charge_ray.get_collider() == player

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
	play_sound("damage", randf_range(-2.0, 0.0), randf_range(0.9, 1.1))

func _update_animation() -> void:
	var dir := _facing
	if state == State.DASH:
		dir = _dash_dir

	_play_walk_4dir(dir)

func _play_walk_4dir(dir: Vector2) -> void:
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

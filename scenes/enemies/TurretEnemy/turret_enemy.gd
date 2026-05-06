extends Enemy

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var bullet_scene = preload("res://scenes/bullets/spit_bullet.tscn")

@export var roam_radius: float = 250.0
@export var repath_time: float = 2.0

@export var idle_min_time: float = 0.6
@export var idle_max_time: float = 1.6
@export var move_min_time: float = 1.0
@export var move_max_time: float = 2.5

var damage: float = 1.0
var lifetime: float = 2.0
var shoot_cooldown: float = 1.5
var can_shoot := true

var _repath_left := 0.0
var _state_time_left := 0.0
var _moving := true

func _ready():
	_get_detector()
	id = 9
	contact_damage = 1.0
	speed = 75.0
	health = 3.0
	knockback_force = 200.0
	knockback_time = 0.0
	knockback_resistance = 0.0

	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 8.0

	sounds = {"shoot": preload("res://assets/audio/sfx/Spit_1.mp3")}
	super._ready()

	_start_move_state()

func _physics_process(delta):
	if is_frozen():
		process_frozen()
		return
	if not is_inside_tree():
		return

	_state_time_left -= delta
	if _state_time_left <= 0.0:
		if _moving:
			_start_idle_state()
		else:
			_start_move_state()

	var move_velocity := Vector2.ZERO

	if _moving:
		_repath_left -= delta
		if _repath_left <= 0.0 or agent.is_navigation_finished():
			_pick_new_roam_target()

		var next_point := agent.get_next_path_position()
		move_velocity = (next_point - global_position).normalized() * get_effective_speed()

	shoot_player()

	if knockback_time > 0:
		knockback_time -= delta
		velocity = move_velocity + knockback
		knockback = knockback.move_toward(
			Vector2.ZERO,
			(knockback.length() / max(knockback_time, 0.01)) * delta
		)
	else:
		knockback = Vector2.ZERO
		velocity = move_velocity

	_update_animation()
	move_and_slide()

func _start_idle_state():
	_moving = false
	_state_time_left = randf_range(idle_min_time, idle_max_time)

func _start_move_state():
	_moving = true
	_state_time_left = randf_range(move_min_time, move_max_time)
	_pick_new_roam_target()

func _pick_new_roam_target():
	_repath_left = repath_time

	var nav_map := agent.get_navigation_map()
	if nav_map == RID():
		return

	for i in range(10):
		var offset := Vector2(
			randf_range(-roam_radius, roam_radius),
			randf_range(-roam_radius, roam_radius)
		)

		var candidate := global_position + offset
		var nav_point := NavigationServer2D.map_get_closest_point(nav_map, candidate)

		if nav_point.distance_to(global_position) < 20.0:
			continue

		agent.target_position = nav_point
		return

func shoot_player():
	if not can_shoot:
		return

	can_shoot = false

	var dirs := [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	for dir in dirs:
		var bullet: Bullet = bullet_scene.instantiate()
		give_bullet_values_with_direction(bullet, dir)
		get_tree().current_scene.add_child(bullet)

	play_shoot_sound()

	await get_tree().create_timer(shoot_cooldown, false).timeout
	can_shoot = true

func give_bullet_values_with_direction(bullet: Bullet, dir: Vector2):
	bullet.init(dir.normalized(), global_position, damage, 75.0, lifetime, 100.0, "enemy")

func _update_animation():
	if velocity == Vector2.ZERO:
		sprite.play("idle")
		return
	sprite.play("walking")
	sprite.flip_h = velocity.x > 0

func _on_damage():
	pass

func play_shoot_sound():
	var pitch := randf_range(0.9, 1.1)
	var volume := randf_range(-1.0, 0.0)
	play_sound("shoot", volume, pitch)

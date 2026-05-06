extends Enemy

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var bullet_scene = preload("res://scenes/bullets/spit_bullet.tscn")
@export var stopping_distance : float = 50.0
var damage: float = 1.0
var lifetime: float = 2.0
var shoot_cooldown : float = 1.5
var can_shoot := true

func _ready():
	_get_detector()
	id = 2
	contact_damage = 1.0
	speed = 40.0
	health = 3.0
	knockback_force = 200.0
	knockback_time = 0.0
	knockback_resistance = 0.0
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = stopping_distance
	sounds = {
		"shoot": preload("res://assets/audio/sfx/Spit_1.mp3")
	}
	super._ready()

func _physics_process(delta):
	if is_frozen():
		process_frozen()
		return

	if not is_inside_tree():
		return
	if player == null:
		return

	var move_velocity : Vector2 = Vector2.ZERO
	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player > stopping_distance:
		agent.target_position = player.global_position
		var next_point = agent.get_next_path_position()
		move_velocity = (next_point - global_position).normalized() * get_effective_speed()
	else:
		shoot_player()

	if knockback_time > 0:
		knockback_time -= delta
		velocity = move_velocity + knockback
		knockback = knockback.move_toward(Vector2.ZERO, (knockback.length() / max(knockback_time, 0.01)) * delta)
	else:
		knockback = Vector2.ZERO
		velocity = move_velocity

	_update_animation()
	move_and_slide()

func shoot_player():
	if not can_shoot:
		return

	can_shoot = false

	var bullet = bullet_scene.instantiate()
	give_bullet_values(bullet)
	get_tree().current_scene.add_child(bullet)
	play_shoot_sound()

	await get_tree().create_timer(shoot_cooldown, false).timeout
	can_shoot = true

func give_bullet_values(bullet: Bullet):
	var forward := (player.global_position - global_position).normalized() * 1
	bullet.init(forward, global_position, damage, 75.0, lifetime, 100.0, "enemy")

func _update_animation():
	if velocity == Vector2.ZERO:
		sprite.play("default")
		return

	var dir = velocity.normalized()

	if abs(dir.x) > abs(dir.y):
		sprite.play("side_walk")
		sprite.flip_h = dir.x > 0
	else:
		if dir.y > 0:
			sprite.play("front_walk")
		else:
			sprite.play("back_walk")

func _on_damage():
	pass

func play_shoot_sound():
	var pitch := randf_range(0.9, 1.1)
	var volume := randf_range(-1.0, 0.0)
	play_sound("shoot", volume, pitch)

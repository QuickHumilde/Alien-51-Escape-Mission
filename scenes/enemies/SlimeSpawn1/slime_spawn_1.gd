extends Enemy

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite = $Visual/AnimatedSprite2D
@export var stopping_distance : float = 1.5

func _ready():
	_get_detector()
	id = 4
	contact_damage = 1.0
	speed = 25.0
	health = 1.0
	knockback_force = 50.0
	knockback_time = 0.0
	knockback_resistance = 0.0
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = stopping_distance
	sounds = {
		"damage": preload("res://assets/audio/sfx/enemies/stalkerenemy/StalkerDamage.mp3")
	}
	super._ready()

func _physics_process(delta):
	if is_frozen():
		process_frozen()
		return
	
	if not is_inside_tree() or player == null:
		return

	var move_velocity : Vector2 = Vector2.ZERO
	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player > stopping_distance:
		agent.target_position = player.global_position
		var next_point = agent.get_next_path_position()
		move_velocity = (next_point - global_position).normalized() * speed

	if knockback_time > 0:
		knockback_time -= delta
		velocity = move_velocity + knockback
		knockback = knockback.move_toward(Vector2.ZERO, (knockback.length() / max(knockback_time, 0.01)) * delta)
	else:
		knockback = Vector2.ZERO
		velocity = move_velocity
	
	_update_animation()
	move_and_slide()

func _update_animation():
	if velocity == Vector2.ZERO:
		sprite.play("default")
		return

	var dir = velocity.normalized()

	# Movimiento horizontal dominante
	if abs(dir.x) > abs(dir.y):
		sprite.play("default")
		sprite.flip_h = dir.x > 0

	# Movimiento vertical dominante
	else:
		if dir.y > 0:
			sprite.play("default")
		else:
			sprite.play("default")

func _on_damage():
	play_damage_sound()

func play_damage_sound():
	var pitch := randf_range(0.9, 1.1)
	var volume := randf_range(-1.0, 0.0)
	play_sound("damage", volume, pitch)

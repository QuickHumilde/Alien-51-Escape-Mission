extends Enemy

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite = $AnimatedSprite2D
@onready var sfx_enemy: AudioStreamPlayer2D

@export var stopping_distance : float = 0.0

var sounds  := {
	"damage": preload("res://assets/audio/sfx/enemies/stalkerenemy/StalkerDamage.mp3")
}

func _ready():
	_get_detector()
	id = 1
	contact_damage = 1.0
	speed = 50.0
	health = 3.0
	knockback_force = 200.0
	knockback_time = 0.0
	knockback_resistance = 50.0

	agent.path_desired_distance = 4.0
	agent.target_desired_distance = stopping_distance
	setup_audio()

func _physics_process(delta):
	if knockback_time > 0:
		knockback_time -= delta
		velocity = knockback
	else:
		if player == null:
			return

		agent.target_position = player.global_position

		var distance_to_player = global_position.distance_to(player.global_position)

		if distance_to_player > stopping_distance:
			var next_point = agent.get_next_path_position()
			var direction = (next_point - global_position).normalized()
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO

	_update_animation()

	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.slide(collision.get_normal())
		move_and_collide(velocity * delta)

func _update_animation():
	if velocity == Vector2.ZERO:
		sprite.play("default")
		return

	var dir = velocity.normalized()

	# Movimiento horizontal dominante
	if abs(dir.x) > abs(dir.y):
		sprite.play("left")
		sprite.flip_h = dir.x > 0

	# Movimiento vertical dominante
	else:
		if dir.y > 0:
			sprite.play("default")
		else:
			sprite.play("default")

func take_damage(damage : float):
	sprite.modulate = Color(1, 0, 0, 1)
	health -= damage
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1,1,1)
	if health <= 0:
		die()
	else:
		play_sound("damage")

func die():
	queue_free()

func setup_audio():
	sfx_enemy = AudioStreamPlayer2D.new()
	sfx_enemy.name = "SFXEnemy"
	sfx_enemy.bus = "SFX"
	sfx_enemy.max_polyphony = 16
	add_child(sfx_enemy)

func play_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0):
	
	sfx_enemy.stream = sounds[sound_name]
	sfx_enemy.volume_db = volume_db
	sfx_enemy.pitch_scale = pitch
	sfx_enemy.play()

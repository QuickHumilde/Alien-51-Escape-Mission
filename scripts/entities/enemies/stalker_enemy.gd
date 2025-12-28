extends Enemy

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite = $AnimatedSprite2D
@export var stopping_distance := 8.0

func _ready():
	_get_detector()
	id=1
	contact_damage=1.0
	speed=50.0
	health=3.0
	knockback_force=200.0
	knockback_time=0.0
	knockback_resistance=50
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = stopping_distance

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

	var collision = move_and_collide(velocity * delta)
	
	if collision:
		velocity = velocity.slide(collision.get_normal())
		move_and_collide(velocity * delta)

func take_damage(damage : float):
	sprite.modulate = Color(1, 0, 0, 1) 
	health -= damage
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1,1,1)
	if health <=0:
		die()

func die():
	queue_free()

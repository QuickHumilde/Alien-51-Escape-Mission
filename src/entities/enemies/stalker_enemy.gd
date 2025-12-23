extends Enemy

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite = $AnimatedSprite2D

func _ready():
	_get_detector()
	id=1
	contact_damage=1.0
	speed=50.0
	health=3.0
	knockback_force=200.0
	knockback_time=0.0
	knockback_resistance=50

func _physics_process(delta):
	if knockback_time > 0:
		knockback_time -= delta
		velocity = knockback
		
	else:
		if player == null:
			return
		
		agent.target_position = player.global_position
		var next_point = agent.get_next_path_position()
		var direction = (next_point - global_position).normalized()
		velocity = direction * speed

	move_and_slide()

func take_damage(damage : float):
	sprite.modulate = Color(1, 0, 0, 1) 
	health -= damage
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1,1,1)
	if health <=0:
		die()

func die():
	queue_free()

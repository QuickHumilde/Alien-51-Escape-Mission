extends Enemy

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite = $Visual/AnimatedSprite2D
@export var stopping_distance : float = 1.5

# --- Growl settings ---
@export var growl_min_interval: float = 2.5
@export var growl_max_interval: float = 4.0
@export var growl_max_distance: float = 220.0
var _growl_timer: Timer

func _ready():
	_get_detector()
	id = 5
	contact_damage = 1.0
	speed = 60.0
	health = 3.0
	knockback_force = 200.0
	knockback_time = 0.0
	knockback_resistance = 0.0
	agent.path_desired_distance = 8.0
	agent.target_desired_distance = stopping_distance
	sounds = {
		"growl": preload("res://assets/audio/sfx/PencilOnPaper.mp3")
	}
	
	super._ready()

	play_growl_sound()
	_setup_growl_timer()

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
		move_velocity = (next_point - global_position).normalized() * get_effective_speed()

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

	if abs(dir.x) > abs(dir.y):
		sprite.play("left")
		sprite.flip_h = dir.x > 0

	else:
		if dir.y > 0:
			sprite.play("front")
		else:
			sprite.play("back")

func _setup_growl_timer() -> void:
	_growl_timer = Timer.new()
	_growl_timer.one_shot = true
	add_child(_growl_timer)
	_growl_timer.timeout.connect(_on_growl_timeout)
	_schedule_next_growl()

func _schedule_next_growl() -> void:
	if _growl_timer == null:
		return
	_growl_timer.start(randf_range(growl_min_interval, growl_max_interval))

func _on_growl_timeout() -> void:
	if not is_inside_tree():
		return

	if player == null:
		_schedule_next_growl()
		return

	if growl_max_distance > 0.0:
		var d := global_position.distance_to(player.global_position)
		if d > growl_max_distance:
			_schedule_next_growl()
			return

	play_growl_sound()
	_schedule_next_growl()

func play_growl_sound():
	var pitch := randf_range(0.9, 1.1)
	var volume := randf_range(0.0, 3.0)
	play_sound("growl", volume, pitch)


func _on_damage():
	pass

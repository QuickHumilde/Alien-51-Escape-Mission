extends CharacterBody2D

@export var speed : float = 35.0
@export var damage : float = 1.0
@onready var timer = $Timer

func _ready() -> void:
	timer.wait_time = 0.25
	timer.one_shot = true
	timer.timeout.connect(_on_hover_complete)

func _physics_process(_delta: float) -> void:
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - position).normalized()
	velocity = direction * speed
	
	if position.distance_to(mouse_position) < 6.5:
		velocity = Vector2.ZERO
		if timer.is_stopped():
			timer.start()
	else:
		timer.stop()

	if velocity.x < 0:
		$Sprite2D.flip_v = true
	else:
		$Sprite2D.flip_v = false

	move_and_slide()
	look_at(mouse_position)

func _on_hover_complete():
	Signals.player_take_damage.emit(damage)

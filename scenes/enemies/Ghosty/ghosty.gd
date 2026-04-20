extends CharacterBody2D

@export var speed: float = 30.0
@export var damage: float = 1.0
@onready var timer: Timer = $Timer
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
var dead: bool = false

func _ready() -> void:
	timer.wait_time = 0.25
	timer.one_shot = true
	timer.timeout.connect(_on_hover_complete)
	Signals.room_cleared.connect(_on_room_cleared)

func _physics_process(_delta: float) -> void:
	if !dead:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var dir: Vector2 = (mouse_pos - global_position)
		var dist = dir.length()

		if dist > 6.5:
			velocity = dir.normalized() * speed
			timer.stop()
		else:
			velocity = Vector2.ZERO
			if timer.is_stopped():
				timer.start()

		sprite.flip_v = velocity.x < 0.0

		move_and_slide()
		look_at(mouse_pos)

func die() -> void:
	dead = true
	sprite.play("dying")
	if get_parent().name == "Enemies":
		reparent(get_tree().root)
	
	await sprite.animation_finished
	queue_free()

func _on_hover_complete() -> void:
	Signals.player_take_damage.emit(damage)

func _on_room_cleared() -> void:
	die()

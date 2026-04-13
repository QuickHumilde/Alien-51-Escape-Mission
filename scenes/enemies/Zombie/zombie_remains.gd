extends Enemy

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite = $Visual/AnimatedSprite2D
var children_spawn: int = 1

func _ready() -> void:
	_get_detector()
	id = 1
	contact_damage = 0.0
	speed = 0.0
	health = 2.0
	knockback_force = 0.0
	knockback_time = 0.0
	knockback_resistance = 50
	sounds = {
		"damage": preload("res://assets/audio/sfx/enemies/stalkerenemy/StalkerDamage.mp3")
	}
	damage_color = Color(0.35, 0.662, 0.252, 1.0)
	start_delayed_action()
	super._ready()

func _physics_process(delta):
	if is_frozen():
		process_frozen()
		return

	if knockback_time > 0:
		knockback_time -= delta
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, (knockback.length() / max(knockback_time, 0.01)) * delta)
	else:
		knockback = Vector2.ZERO
		velocity = Vector2.ZERO

	move_and_slide()

func apply_knockback(dir: Vector2, force: float = 500.0, duration: float = 0.2) -> void:
	if knockback_resistance < force:
		knockback = dir * (force - knockback_resistance)
		knockback_time = duration

func _on_damage():
	play_damage_sound()

func play_damage_sound():
	var pitch := randf_range(0.9, 1.1)
	var volume := randf_range(-1.0, 0.0)
	play_sound("damage", volume, pitch)

func start_delayed_action():
	await get_tree().create_timer(2.5).timeout
	sprite.position.y -= 10
	sprite.play("regenerating")
	await sprite.animation_finished
	no_mori_jisjisjis()

func no_mori_jisjisjis():
	var zombie_scene = load("res://scenes/enemies/Zombie/zombie_enemy.tscn")
	var enemies_container = get_parent()
	while enemies_container != null and enemies_container.name != "Enemies":
			enemies_container = enemies_container.get_parent()
	if enemies_container == null:
		enemies_container = get_tree().current_scene
	for i in range(children_spawn):
		var brains = zombie_scene.instantiate()
		if brains == null:
			print("No cerebros para ti hoy")
			queue_free()
			return

		enemies_container.add_child(brains)
		brains.global_position = sprite.global_position
	queue_free()

func do_damage(_body) -> void:
	pass

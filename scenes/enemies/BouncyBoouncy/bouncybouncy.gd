extends Enemy

# =============================================================================
# REFERENCIAS A NODOS
# =============================================================================

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var collision: CollisionShape2D = $Hitbox

# Escena del enemigo a generar
@onready var enemy_scene: PackedScene = preload("res://scenes/enemies/SlimeSpawn1/slime_spawn_1.tscn")

# =============================================================================
# MÁQUINA DE ESTADOS
# =============================================================================

enum State { ROLLING, SPAWNING }
var state: State = State.ROLLING
var _last_state: State = State.ROLLING

# =============================================================================
# PARÁMETROS EXPORTADOS
# =============================================================================

@export var roll_speed: float = 200.0
@export var max_speed: float = 200.0
@export var acceleration: float = 100.0
@export var spawn_interval: float = 4.0                                                     
@export var min_spawn_count: int = 3
@export var max_spawn_count: int = 5
@export var spawn_radius: float = 10.0
@export var spawn_vertical_range: float = 10.0
@export var bounce_damping: float = 0.6
@export var knockback_resistance_value: float = 182.5


var _t: float = 0.0
var _spawn_timer: float = 0.0

# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	_get_detector()

	id = 12
	contact_damage = 1.0
	health = 35.0

	sounds = { "slime_1": load("res://assets/audio/sfx/Slime_1-SFX.mp3") }
	
	Signals.boss_detected.emit(self, "BouncyBouncy")

	speed = roll_speed
	knockback_force = 500.0
	knockback_time = 0.0
	knockback_resistance = knockback_resistance_value

	_last_state = state
	super._ready()

# =============================================================================
# BUCLE PRINCIPAL DE FÍSICA
# =============================================================================

func _physics_process(delta: float) -> void:
	if is_frozen():
		process_frozen()
		return
	if player == null:
		return

	_t += delta
	_spawn_timer += delta

	match state:
		State.ROLLING:
			_process_rolling(delta)
		State.SPAWNING:
			_process_spawning(delta)

	if state != _last_state:
		_on_state_changed(_last_state, state)
		_last_state = state

	_update_animation()

# =============================================================================
# TRANSICIONES DE ESTADO
# =============================================================================

func _on_state_changed(_from_state: State, to_state: State) -> void:
	if to_state == State.SPAWNING:
		_on_spawn_start()

# =============================================================================
# ESTADOS DE IA
# =============================================================================

func _process_rolling(delta: float) -> void:
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()

	if dist > 0.001:
		var dir := to_player.normalized()
		velocity = velocity.move_toward(dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)

	if knockback_time > 0.0:
		knockback_time -= delta
		velocity += knockback  # AÑADE ESTA LÍNEA
		knockback = knockback.move_toward(Vector2.ZERO, (knockback.length() / max(knockback_time, 0.01)) * delta)

	move_and_slide()
	_handle_wall_bounce()

	if _spawn_timer >= spawn_interval:
		state = State.SPAWNING
		_spawn_timer = 0.0
		_t = 0.0
	
func _process_spawning(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	
# =============================================================================
# LÓGICA DE REBOTE EN PAREDES
# =============================================================================

func _handle_wall_bounce() -> void:
	var collision_count := get_slide_collision_count()
	
	for i in range(collision_count):
		var collision := get_slide_collision(i)
		if collision == null:
			continue

		var normal := collision.get_normal()
		velocity = velocity.reflect(normal) * bounce_damping

# =============================================================================
# SPAWN DE ENEMIGOS
# =============================================================================

func _on_spawn_start() -> void:
	var spawn_count := randi_range(min_spawn_count, max_spawn_count)

	for i in range(spawn_count):
		_spawn_enemy()
	
	play_sound("slime_1")

	state = State.ROLLING
	_t = 0.0

func _spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	
	var offset = Vector2(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_vertical_range, spawn_vertical_range))
	enemy.global_position = self.position + offset
	
	var enemies_container = get_parent()
	while enemies_container != null and enemies_container.name != "Enemies":
		enemies_container = enemies_container.get_parent()

	if enemies_container == null:
		enemies_container = get_tree().current_scene

	enemies_container.add_child(enemy)

# =============================================================================
# KNOCKBACK Y DAÑO
# =============================================================================

func _on_damage() -> void:
	pass

# =============================================================================
# ANIMACIÓN
# =============================================================================

func _update_animation() -> void:
	if not is_instance_valid(sprite):
		return

	if velocity.length_squared() > 0.0001:
		sprite.rotation += velocity.length() * 0.0005
	
	if velocity.length_squared() > 0.0001:
		if sprite.animation != "roll":
			#sprite.play("roll")
			sprite.play("idle")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func die() -> void:
	Signals.boss_died.emit()
	super.die()

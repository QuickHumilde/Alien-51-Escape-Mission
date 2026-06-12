extends Enemy

# =============================================================================
# REFERENCIAS A NODOS
# =============================================================================

@onready var sprite:       AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var hitbox:       CollisionShape2D = $Hitbox
@onready var detector:     Area2D           = $Detector
@onready var shoot_light:  PointLight2D     = $ShootLight

var bullet_scene: PackedScene = preload("res://scenes/bullets/blue_marker_bullet.tscn")
var enemy_scene:  PackedScene = preload("res://scenes/enemies/stickman/stickman_enemy.tscn")

# =============================================================================
# ESTADOS
# =============================================================================

enum State {
	IDLE,
	WINDUP,
	SHOOT,
	REST
}

var state:       State = State.IDLE
var _last_state: State = State.IDLE

# =============================================================================
# PARÁMETROS EXPORTADOS
# =============================================================================

@export var bullets_per_burst:  int   = 5
@export var burst_interval:     float = 0.15
@export var rest_time:          float = 3.0
@export var bullet_speed:       float = 200.0
@export var bullet_spread:      float = TAU

@export var windup_time:        float = 1.2

@export var enemies_per_spawn:  int   = 1
@export var spawn_interval:     float = 4.0

# =============================================================================
# VARIABLES INTERNAS
# =============================================================================

var _t:             float = 0.0
var _bullets_fired: int   = 0
var _spawn_timer:   float = 0.0

# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	_get_detector()

	id               = 30
	contact_damage   = 1.0
	health           = 60.0
	sounds           = { "windup": load("res://assets/audio/sfx/Charge SFX.mp3") }

	speed                = 0.0
	knockback_force      = 0.0
	knockback_resistance = 9999999999.0

	shoot_light.enabled = false
	shoot_light.energy  = 0.0

	Signals.boss_detected.emit(self, "Fernancil")

	_last_state = state
	super._ready()

# =============================================================================
# LOOP PRINCIPAL
# =============================================================================

func _physics_process(delta: float) -> void:
	if is_frozen():
		process_frozen()
		return
	if player == null:
		return

	_t           += delta
	_spawn_timer += delta

	if _spawn_timer >= spawn_interval:
		_spawn_enemies()
		_spawn_timer = 0.0

	match state:
		State.IDLE:   _process_idle(delta)
		State.WINDUP: _process_windup(delta)
		State.SHOOT:  _process_shoot(delta)
		State.REST:   _process_rest(delta)

	if state != _last_state:
		_on_state_changed(_last_state, state)
		_last_state = state

# =============================================================================
# TRANSICIONES
# =============================================================================

func _on_state_changed(from_state: State, to_state: State) -> void:
	if to_state == State.WINDUP:
		play_sound("windup")

	if to_state == State.SHOOT:
		_bullets_fired = 0
		_t             = 0.0

# =============================================================================
# ESTADOS
# =============================================================================

func _process_idle(_delta: float) -> void:
	state = State.WINDUP
	_t    = 0.0

func _process_windup(_delta: float) -> void:
	shoot_light.enabled = true
	shoot_light.energy  = lerp(0.0, 3.0, _t / windup_time)

	if _t >= windup_time:
		state = State.SHOOT
		_t    = 0.0

func _process_shoot(_delta: float) -> void:
	shoot_light.energy = lerp(3.0, 0.5, _t / (burst_interval * bullets_per_burst))

	if _t >= burst_interval:
		_fire_bullet()
		_bullets_fired += 1
		_t              = 0.0

	if _bullets_fired >= bullets_per_burst:
		shoot_light.enabled = false
		shoot_light.energy  = 0.0
		state               = State.REST
		_t                  = 0.0

func _process_rest(_delta: float) -> void:
	if _t >= rest_time:
		state = State.WINDUP
		_t    = 0.0

# =============================================================================
# DISPARO DE BALAS
# =============================================================================

func _fire_bullet() -> void:
	if bullet_scene == null:
		push_error("ERROR: bullet_scene es NULL.")
		return

	var angle     = randf_range(0.0, bullet_spread)
	var direction = Vector2.RIGHT.rotated(angle)

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.init(
		direction,
		global_position,
		1.0,
		50.0,
		5.0,
		bullet_speed,
        "enemy"
	)

# =============================================================================
# INVOCACIÓN DE ENEMIGOS
# =============================================================================

func _spawn_enemies() -> void:
	if enemy_scene == null:
		push_error("ERROR: enemy_scene es NULL.")
		return

	for i in enemies_per_spawn:
		var enemy = enemy_scene.instantiate()

		var offset = Vector2(
			randf_range(-35.0, 45.0),
			randf_range(-35.0, 45.0)
		)

		var enemies_container = get_parent()
		while enemies_container != null and enemies_container.name != "Enemies":
			enemies_container = enemies_container.get_parent()

		if enemies_container == null:
			enemies_container = get_tree().current_scene

		enemies_container.add_child(enemy)
		enemy.global_position = global_position + offset
		enemy.speed          *= 0.4

# =============================================================================
# DAÑO
# =============================================================================

func _on_damage() -> void:
	pass

func die() -> void:
	Signals.boss_died.emit()
	super.die()

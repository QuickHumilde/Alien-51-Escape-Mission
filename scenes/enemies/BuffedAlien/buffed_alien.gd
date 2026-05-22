extends Enemy

# =============================================================================
# REFERENCIAS A NODOS
# =============================================================================

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var visual = $Visual
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var detector: Area2D = $Detector
@onready var detector_shape: CollisionShape2D = $Detector/CollisionShape2D
# Rayo usado para detectar obstáculos antes de lanzar el dash
@onready var charge_ray: RayCast2D = $ChargeRay
# Partículas emitidas durante el dash
@onready var dash_particles: GPUParticles2D = $DashParticles
# Escena del proyectil disparado en los ataques
@onready var bullet_scene: PackedScene = preload("res://scenes/bullets/player_bullet.tscn")


# =============================================================================
# MÁQUINA DE ESTADOS
# =============================================================================

# Estados de la IA del boss
enum State {
	CHASE,
	BURROW,
	UNDERGROUND_MOVE,
	EMERGE_WINDUP,
	EMERGE_WAIT,
	DASH_WINDUP,
	DASH,
	REST
}

# Tipos de ataque al emerger
enum AttackType { FAN3, CARDINAL4, BURST }
# Patrones de disparo durante el descanso
enum RestPattern { CARDINAL4, DIAGONAL4, RANDOM }

var state: State = State.CHASE
# Guarda el estado anterior para detectar transiciones
var _last_state: State = State.CHASE
var _attack: AttackType = AttackType.FAN3
var _rest_pattern: RestPattern = RestPattern.CARDINAL4


# =============================================================================
# PARÁMETROS EXPORTADOS
# =============================================================================

# Velocidades de movimiento en superficie y bajo tierra
@export var surface_speed: float = 45.0
@export var underground_speed: float = 140.0
# Distancia a la que el boss deja de perseguir e inicia el combo
@export var stopping_distance: float = 220.0

# Tiempos de cada fase de la secuencia de emergencia
@export var burrow_time: float = 0.45
@export var underground_move_time: float = 0.8
@export var emerge_windup_time: float = 0.35
@export var emerge_wait_time: float = 0.40

# Parámetros del dash
@export var dash_speed: float = 300.0
@export var dash_time: float = 0.35
@export var dash_windup_time: float = 0.18
# Si es true, las partículas se emiten de forma continua durante el dash
@export var dash_particles_continuous: bool = true

# Acumulador de tiempo del dash y dirección tomada
var _dash_t: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT

# Número de dashes por combo (aleatorio entre min y max)
@export var combo_min_repeats: int = 2
@export var combo_max_repeats: int = 5
# Tiempo de descanso entre combos
@export var rest_time: float = 3.0

# Contadores del combo actual
var _combo_target_repeats: int = 0
var _combo_done_repeats: int = 0

# Margen y radio para elegir posiciones aleatorias bajo tierra
@export var random_target_margin: float = 64.0
@export var random_target_radius: Vector2 = Vector2(260, 170)

# Acumulador de tiempo general de estado
var _t: float = 0.0
# Posición objetivo bajo tierra
var _dash_target: Vector2 = Vector2.ZERO
# Última dirección de movimiento (orienta los ataques)
var _facing: Vector2 = Vector2.RIGHT

# Parámetros de los proyectiles
@export var damage: float = 1.0
@export var bullet_speed: float = 95.0
@export var bullet_lifetime: float = 2.0
# Dispersión del abanico de 3 proyectiles en grados
@export var fan_spread_deg: float = 18.0
# Parámetros del ataque en ráfaga
@export var burst_count: int = 4
@export var burst_gap: float = 0.12

# Si es true, dispara al inicio de cada dash del combo
@export var shoot_on_each_dash_start: bool = true

# Control de disparos durante el estado de descanso
@export var rest_shoot_on_enter: bool = true
@export var rest_shoot_interval: float = 0.0

# Rango de disparos/balas para el patrón aleatorio del descanso
@export var rest_random_min_shots: int = 4
@export var rest_random_max_shots: int = 7
@export var rest_random_min_bullets: int = 6
@export var rest_random_max_bullets: int = 12

# Flags internos del disparo de descanso
var _rest_shot_done: bool = false
var _rest_shot_timer: float = 0.0

# Si es true, el boss es invulnerable y sin colisión mientras está bajo tierra
@export var invulnerable_underground: bool = true
@export var disable_collision_underground: bool = true

# Nombres de animaciones clave
@export var anim_burrow: StringName = &"burrow"
@export var anim_emerge: StringName = &"emerge"
@export var anim_dash: StringName = &"dash"
@export var anim_shoot: StringName = &"shoot"

# Duración de los fundidos al entrar/salir del suelo
@export var fade_out_time: float = 0.1
@export var fade_in_time: float = 0.1

# Intensidad del temblor de cámara en dash e impacto
@export var dash_shake_amount: float = 6.0
@export var impact_shake_amount: float = 8.0

# Parámetros de audio del dash
@export var dash_accel_volume_db: float = -5.0
@export var dash_accel_pitch_min: float = 0.6
@export var dash_accel_pitch_max: float = 0.8

# Parámetros de audio del impacto
@export var impact_volume_db: float = 0.0
@export var impact_pitch_min: float = 0.9
@export var impact_pitch_max: float = 1.1

# Estado interno del fundido de alpha
var _fading: bool = false
var _fade_t: float = 0.0
var _fade_from: float = 1.0
var _fade_to: float = 1.0


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	_get_detector()

	id = 9
	contact_damage = 2.0
	health = 45.0

	sounds = { "acceleration_1" : load("res://assets/audio/sfx/Dash_1.mp3") }

	speed = surface_speed
	knockback_force = 800.0
	knockback_time = 0.0
	# Resistencia al knockback prácticamente infinita
	knockback_resistance = 100000000.0

	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 8.0

	if charge_ray != null:
		charge_ray.add_exception(self)
		charge_ray.enabled = true

	if is_instance_valid(dash_particles):
		dash_particles.emitting = false

	_set_visual_alpha(1.0)

	_last_state = state
	super._ready()


# =============================================================================
# BUCLE PRINCIPAL DE FÍSICA
# =============================================================================

# Actualiza el acumulador de tiempo, el fundido y despacha el estado activo.
# Detecta transiciones de estado y actualiza la animación cada frame.
func _physics_process(delta: float) -> void:
	if is_frozen():
		process_frozen()
		return
	if player == null:
		return

	_t += delta
	_process_fade(delta)

	match state:
		State.CHASE:
			_process_chase(delta)
		State.BURROW:
			_process_burrow(delta)
		State.UNDERGROUND_MOVE:
			_process_underground_move(delta)
		State.EMERGE_WINDUP:
			_process_emerge_windup(delta)
		State.EMERGE_WAIT:
			_process_emerge_wait(delta)
		State.DASH_WINDUP:
			_process_dash_windup(delta)
		State.DASH:
			_process_dash(delta)
		State.REST:
			_process_rest(delta)

	if state != _last_state:
		_on_state_changed(_last_state, state)
		_last_state = state

	_update_animation()


# =============================================================================
# TRANSICIONES DE ESTADO
# =============================================================================

# Gestiona efectos de entrada/salida de cada estado: animaciones, fundidos y FX.
func _on_state_changed(from_state: State, to_state: State) -> void:
	if to_state == State.BURROW:
		_play_anim_if_exists(anim_burrow)
		_start_fade_to(0.0, fade_out_time)

	if to_state == State.UNDERGROUND_MOVE:
		_set_underground(true)

	if to_state == State.EMERGE_WAIT:
		_set_underground(false)
		_play_anim_if_exists(anim_emerge)
		_start_fade_to(1.0, fade_in_time)

	if to_state == State.DASH_WINDUP:
		_on_acceleration()

	if to_state == State.DASH:
		_fx_dash_start()

	if from_state == State.DASH and to_state != State.DASH:
		_fx_dash_end()

# Reproduce una animación solo si el sprite y la animación son válidos.
func _play_anim_if_exists(anim: StringName) -> void:
	if not is_instance_valid(sprite):
		return
	if anim == &"":
		return
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(anim):
		return
	if sprite.animation != anim:
		sprite.play(anim)

# Activa o desactiva el modo subterráneo: colisiones, detector, daño e invulnerabilidad.
func _set_underground(value: bool) -> void:
	if disable_collision_underground and is_instance_valid(hitbox):
		hitbox.set_deferred("disabled", value)

	if is_instance_valid(detector):
		detector.set_deferred("monitoring", not value)
		detector.set_deferred("monitorable", not value)

	if is_instance_valid(detector_shape):
		detector_shape.set_deferred("disabled", value)

	contact_damage = 0.0 if value else 2.0
	if invulnerable_underground:
		set_meta("invulnerable", value)


# =============================================================================
# EFECTOS VISUALES DEL DASH
# =============================================================================

# Activa las partículas del dash al iniciar el estado DASH.
func _fx_dash_start() -> void:
	if not is_instance_valid(dash_particles):
		return

	if dash_particles_continuous:
		dash_particles.emitting = true
	else:
		dash_particles.emitting = false
		dash_particles.restart()
		dash_particles.emitting = true

# Detiene las partículas al salir del estado DASH.
func _fx_dash_end() -> void:
	if not is_instance_valid(dash_particles):
		return
	dash_particles.emitting = false


# =============================================================================
# ESTADOS DE IA
# =============================================================================

# CHASE: persigue al jugador en superficie. Inicia un combo cuando está suficientemente cerca.
func _process_chase(delta: float) -> void:
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()

	if dist > 0.001:
		var dir := to_player / dist
		_facing = dir
		if dist > stopping_distance:
			agent.target_position = player.global_position
			var next_point := agent.get_next_path_position()
			velocity = (next_point - global_position).normalized() * surface_speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	if knockback_time > 0.0:
		velocity += knockback

	move_and_slide()
	_decay_knockback(delta)

	if dist <= 600.0:
		_start_combo()
		state = State.BURROW
		_t = 0.0
		velocity = Vector2.ZERO

# Inicializa los contadores del combo eligiendo un número aleatorio de dashes.
func _start_combo() -> void:
	_combo_done_repeats = 0
	_combo_target_repeats = randi_range(combo_min_repeats, combo_max_repeats)

# BURROW: quieto mientras dura la animación de excavar; luego elige destino bajo tierra.
func _process_burrow(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _t >= burrow_time:
		_pick_random_room_target()
		state = State.UNDERGROUND_MOVE
		_t = 0.0

# Elige una posición aleatoria dentro de los límites de la sala como destino bajo tierra.
func _pick_random_room_target() -> void:
	var rect := _get_room_bounds()

	if rect.size == Vector2.ZERO:
		var center := player.global_position
		rect = Rect2(center - random_target_radius, random_target_radius * 2.0)

	rect.position += Vector2.ONE * random_target_margin
	rect.size -= Vector2.ONE * (random_target_margin * 2.0)
	if rect.size.x < 10.0 or rect.size.y < 10.0:
		rect = Rect2(player.global_position - random_target_radius, random_target_radius * 2.0)

	_dash_target = Vector2(
		randf_range(rect.position.x, rect.position.x + rect.size.x),
		randf_range(rect.position.y, rect.position.y + rect.size.y)
	)

	agent.target_position = _dash_target

# Devuelve los límites de la sala actual (stub; retorna Rect2 vacío por defecto).
func _get_room_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2.ZERO)

# UNDERGROUND_MOVE: navega bajo tierra hacia _dash_target usando el agente de navegación.
func _process_underground_move(_delta: float) -> void:
	agent.target_position = _dash_target
	var next_point := agent.get_next_path_position()

	var dir := (next_point - global_position)
	if dir.length() > 0.001:
		dir = dir.normalized()
		velocity = dir * underground_speed
		_facing = dir
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	var dist_to_target := global_position.distance_to(_dash_target)
	if dist_to_target <= 18.0 or _t >= underground_move_time:
		state = State.EMERGE_WINDUP
		_t = 0.0
		velocity = Vector2.ZERO

# EMERGE_WINDUP: pausa breve antes de emerger; elige el tipo de ataque.
func _process_emerge_windup(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _t >= emerge_windup_time:
		_choose_attack()
		state = State.EMERGE_WAIT
		_t = 0.0

# EMERGE_WAIT: el boss ha emergido y espera antes de lanzar el dash.
func _process_emerge_wait(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _t >= emerge_wait_time:
		state = State.DASH_WINDUP
		_t = 0.0

# DASH_WINDUP: pausa de telegrafía antes del dash; fija la dirección hacia el jugador.
func _process_dash_windup(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _t >= dash_windup_time:
		var dir := (player.global_position - global_position)
		_dash_dir = dir.normalized() if dir.length() > 0.001 else _facing
		_facing = _dash_dir
		_dash_t = 0.0
		state = State.DASH
		_t = 0.0

# DASH: el boss se lanza en línea recta; dispara al inicio si está configurado.
# Termina al chocar con una pared o al superar dash_time.
func _process_dash(delta: float) -> void:
	_dash_t += delta

	velocity = _dash_dir * dash_speed
	move_and_slide()

	if shoot_on_each_dash_start and _dash_t <= 0.001:
		await _do_attack_pattern()

	if is_on_wall() or get_slide_collision_count() > 0:
		_try_break_obstacle_on_dash()
		_on_impact()
		_end_dash_after_impact()
		return

	if _dash_t >= dash_time:
		_end_dash_after_impact()

# Incrementa el contador de dashes del combo; si se completaron todos, pasa a REST,
# si no, vuelve a excavar para el siguiente dash.
func _end_dash_after_impact() -> void:
	_combo_done_repeats += 1

	if _combo_done_repeats >= _combo_target_repeats:
		_rest_shot_done = false
		_rest_shot_timer = 0.0
		state = State.REST
		_t = 0.0
		velocity = Vector2.ZERO
		return

	state = State.BURROW
	_t = 0.0
	velocity = Vector2.ZERO

# REST: el boss descansa y dispara patrones de proyectiles según la configuración.
# Vuelve a CHASE al expirar rest_time.
func _process_rest(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if rest_shoot_on_enter:
		if rest_shoot_interval <= 0.0:
			if not _rest_shot_done:
				_rest_shot_done = true
				_fire_rest_pattern()
		else:
			_rest_shot_timer += delta
			if _rest_shot_timer >= rest_shoot_interval:
				_rest_shot_timer = 0.0
				_fire_rest_pattern()

	if _t >= rest_time:
		_rest_shot_done = false
		_rest_shot_timer = 0.0
		state = State.CHASE
		_t = 0.0


# =============================================================================
# ATAQUES
# =============================================================================

# Elige aleatoriamente el tipo de ataque con probabilidades ponderadas.
func _choose_attack() -> void:
	var r := randf()
	if r < 0.40:
		_attack = AttackType.FAN3
	elif r < 0.75:
		_attack = AttackType.CARDINAL4
	else:
		_attack = AttackType.BURST

# Ejecuta el patrón de ataque elegido con su animación.
func _do_attack_pattern() -> void:
	_play_anim_if_exists(anim_shoot)
	match _attack:
		AttackType.FAN3:
			_attack_fan3()
		AttackType.CARDINAL4:
			_attack_cardinal4()
		AttackType.BURST:
			await _attack_burst()

# Dispara 3 proyectiles en abanico hacia el jugador.
func _attack_fan3() -> void:
	var to_player := (player.global_position - global_position)
	var base_dir := to_player.normalized() if to_player.length() > 0.001 else _facing
	var spread := deg_to_rad(fan_spread_deg)
	var dirs := [base_dir.rotated(-spread), base_dir, base_dir.rotated(spread)]
	for d in dirs:
		_spawn_bullet(d)

# Dispara 4 proyectiles en las 4 direcciones cardinales.
func _attack_cardinal4() -> void:
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for d in dirs:
		_spawn_bullet(d)

# Dispara burst_count proyectiles hacia el jugador con burst_gap de pausa entre cada uno.
func _attack_burst() -> void:
	for i in range(burst_count):
		var to_player := (player.global_position - global_position)
		var dir := to_player.normalized() if to_player.length() > 0.001 else _facing
		_spawn_bullet(dir)
		await get_tree().create_timer(burst_gap).timeout

# Elige y ejecuta un patrón de disparo durante el estado de descanso.
func _fire_rest_pattern() -> void:
	_choose_rest_pattern()
	match _rest_pattern:
		RestPattern.CARDINAL4:
			_fire_cardinal4()
		RestPattern.DIAGONAL4:
			_fire_diagonal4()
		RestPattern.RANDOM:
			_fire_random()

# Elige aleatoriamente el patrón de disparo del descanso.
func _choose_rest_pattern() -> void:
	var r := randf()
	if r < 0.34:
		_rest_pattern = RestPattern.CARDINAL4
	elif r < 0.67:
		_rest_pattern = RestPattern.DIAGONAL4
	else:
		_rest_pattern = RestPattern.RANDOM

# Patrón de descanso: 4 proyectiles en direcciones cardinales.
func _fire_cardinal4() -> void:
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for d in dirs:
		_spawn_bullet(d)

# Patrón de descanso: 4 proyectiles en direcciones diagonales.
func _fire_diagonal4() -> void:
	var dirs := [
		Vector2(-1, -1).normalized(),
		Vector2( 1, -1).normalized(),
		Vector2(-1,  1).normalized(),
		Vector2( 1,  1).normalized(),
	]
	for d in dirs:
		_spawn_bullet(d)

# Patrón de descanso: número aleatorio de proyectiles en direcciones completamente aleatorias.
func _fire_random() -> void:
	var n := randi_range(rest_random_min_bullets, rest_random_max_bullets)
	for i in range(n):
		var a := randf_range(0.0, TAU)
		var d := Vector2(cos(a), sin(a))
		_spawn_bullet(d)

# Instancia y lanza un proyectil en la dirección indicada.
func _spawn_bullet(dir: Vector2) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.init(dir, global_position, damage, bullet_speed, bullet_lifetime, 100.0, "enemy")
	get_tree().current_scene.add_child(bullet)

# Intenta romper o golpear el obstáculo con el que colisionó el dash
# recorriendo la jerarquía del nodo colisionado.
func _try_break_obstacle_on_dash() -> void:
	var count := get_slide_collision_count()
	for i in range(count):
		var col := get_slide_collision(i)
		if col == null:
			continue

		var c := col.get_collider()
		if c == null:
			continue

		var node := c as Node
		while node != null:
			if node.has_method("break_now"):
				node.call("break_now")
				return
			if node.has_method("receive_hit"):
				node.call("receive_hit")
				return
			node = node.get_parent()


# =============================================================================
# EFECTOS DE SONIDO Y CÁMARA
# =============================================================================

# Emite el temblor de cámara y reproduce el SFX de aceleración al inicio del dash_windup.
func _on_acceleration() -> void:
	Signals.shake_camera.emit(dash_shake_amount)
	var pitch: float = randf_range(dash_accel_pitch_min, dash_accel_pitch_max)
	play_sound("acceleration_1", dash_accel_volume_db, pitch)

# Emite el temblor de cámara y reproduce el SFX de impacto al chocar durante el dash.
func _on_impact() -> void:
	Signals.shake_camera.emit(impact_shake_amount)
	var pitch: float = randf_range(impact_pitch_min, impact_pitch_max)
	AudioManager.play_sfx("crash_1", impact_volume_db, pitch)


# =============================================================================
# FUNDIDO DE ALPHA
# =============================================================================

# Inicia un fundido del alpha visual del boss hacia el valor indicado en el tiempo dado.
func _start_fade_to(alpha: float, time: float) -> void:
	if not is_instance_valid(visual):
		return
	_fading = true
	_fade_t = 0.0
	_fade_from = visual.modulate.a
	_fade_to = clampf(alpha, 0.0, 1.0)
	if time <= 0.0:
		_set_visual_alpha(_fade_to)
		_fading = false

# Interpola el alpha visual del boss cada frame mientras _fading es true.
func _process_fade(delta: float) -> void:
	if not _fading or not is_instance_valid(visual):
		return

	var duration := fade_in_time if _fade_to > _fade_from else fade_out_time
	duration = maxf(duration, 0.0001)

	_fade_t += delta
	var t01 := clampf(_fade_t / duration, 0.0, 1.0)
	var a := lerpf(_fade_from, _fade_to, t01)
	_set_visual_alpha(a)

	if t01 >= 1.0:
		_fading = false

# Asigna directamente el canal alpha del nodo visual.
func _set_visual_alpha(a: float) -> void:
	if not is_instance_valid(visual):
		return
	var m = visual.modulate
	m.a = clampf(a, 0.0, 1.0)
	visual.modulate = m


# =============================================================================
# KNOCKBACK Y DAÑO
# =============================================================================

# Reduce gradualmente el knockback hasta cero a lo largo de knockback_time.
func _decay_knockback(delta: float) -> void:
	if knockback_time > 0.0:
		knockback_time -= delta
		knockback = knockback.move_toward(
			Vector2.ZERO,
			(knockback.length() / max(knockback_time, 0.01)) * delta
		)
	else:
		knockback = Vector2.ZERO

# Implementación de _on_damage: ignora el daño si está bajo tierra e invulnerable.
func _on_damage() -> void:
	if invulnerable_underground and get_meta("invulnerable", false) == true:
		return
	pass


# =============================================================================
# ANIMACIÓN
# =============================================================================

# Selecciona la animación correcta según el estado activo del boss.
func _update_animation() -> void:
	match state:
		State.BURROW:
			_play_anim_if_exists(anim_burrow)
			return

		State.UNDERGROUND_MOVE:
			return

		State.EMERGE_WINDUP, State.EMERGE_WAIT:
			_play_anim_if_exists(anim_emerge)
			return

		State.DASH_WINDUP, State.DASH:
			_play_walk_from_dir(_dash_dir)
			return

		State.CHASE:
			if velocity.length_squared() > 0.0001:
				_play_walk_from_dir(velocity)
			return

		State.REST:
			_play_anim_if_exists(&"rest")
			return

		_:
			return

# Reproduce la animación de caminar correcta según la dirección de movimiento,
# aplicando flip horizontal cuando se mueve hacia la derecha.
func _play_walk_from_dir(dir_in: Vector2) -> void:
	if not is_instance_valid(sprite):
		return

	var dir := dir_in
	if dir.length_squared() < 0.0001:
		dir = _facing
	if dir.length_squared() < 0.0001:
		dir = Vector2.DOWN

	dir = dir.normalized()

	var anim := ""
	var flip_h := false

	if absf(dir.x) > absf(dir.y):
		anim = "walk_left"
		flip_h = dir.x > 0.0
	else:
		anim = "walk_front" if dir.y > 0.0 else "walk_back"
		flip_h = false

	if sprite.animation != anim:
		sprite.play(anim)
	sprite.flip_h = flip_h

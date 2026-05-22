extends CharacterBody2D
class_name Character

# =============================================================================
# REFERENCIAS A NODOS (COMPONENTES)
# =============================================================================

# Nodo raíz de los elementos visuales del personaje
@onready var visuals: Node2D = $Visual
# Sprite animado principal
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
# Componente de movimiento
@onready var movement: CharacterMovement = $Logic/Movement
# Componente de animación
@onready var animation: CharacterAnimation = $Logic/Animation
# Componente de combate y armas
@onready var combat: CharacterCombat = $Logic/Combat
# Componente de estadísticas
@onready var stats: CharacterStats = $Logic/Stats
# Componente de habilidades activas
@onready var abilities: CharacterAbilities = $Logic/Abilities
# Inventario del jugador (ítems, dinero, modificadores)
@onready var inventory: PlayerInventory = $Logic/Inventory
# Componente que gestiona la recogida y aplicación de ítems
@onready var items: CharacterItems = $Logic/Items
# Componente de audio del personaje
@onready var audio: CharacterAudio = $Logic/Audio
# Timer de invulnerabilidad tras recibir daño
@onready var damage_timer = $Logic/DamageTimer
# Colisión del hitbox del jugador (área que recibe daño)
@onready var hitbox: CollisionShape2D = $Hitbox
# Colisión del detector de hitbox enemigo
@onready var hitbox_detector: CollisionShape2D = $Detector/HitboxDetector
# Área que detecta colisiones con enemigos para aplicar daño de contacto
@onready var detector_area: Area2D = $Detector
# Área que detecta trampas en el suelo
@onready var tramp_detector_area: Area2D = $TrampDetector
# Colisión del detector de trampas
@onready var tramp_detector_area_hitbox: CollisionShape2D = $TrampDetector/CollisionShape2D
# Nodo padre donde se instancian las armas
@onready var weapon_holder = $WeaponHolder
# Cámara del jugador
@onready var camera: Camera2D = $PlayerCamera


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready():
	# Conecta las señales globales relevantes para el jugador
	tramp_detector_area.area_entered.connect(_on_tramp_detector_area_entered)
	Signals.player_death.connect(player_death)
	Signals.show_death_menu.connect(_on_show_death_menu)
	Signals.player_revive.connect(player_revive)
	Signals.player_take_damage.connect(take_damage)

	# Inicializa cada componente pasándole las referencias que necesita
	combat.init(weapon_holder, stats)
	inventory.init(self)
	items.init(self)
	stats.init(sprite, audio, animation, hitbox_detector, hitbox, visuals, tramp_detector_area_hitbox, inventory)
	movement.init(self)
	abilities.init(self)
	animation.init(sprite, damage_timer, weapon_holder)


# =============================================================================
# BUCLE PRINCIPAL
# =============================================================================

func _process(_delta):
	# Delega la lógica de cada frame a los componentes correspondientes
	movement.update(_delta, self)
	animation.update(self)
	combat.update(_delta, self)

	# --------REMOVE---------------
	if Input.is_action_just_pressed("god_mode"):
		god_mode()
	if Input.is_action_just_pressed("open_doors"):
		Signals.room_cleared.emit()

func _physics_process(_delta):
	# Aplica el movimiento calculado por CharacterMovement al CharacterBody2D
	move_and_slide()


# =============================================================================
# RECEPCIÓN DE DAÑO
# =============================================================================

# Gestiona el daño entrante respetando el timer de invulnerabilidad.
# Permite a los modificadores reducir o evitar el daño antes de aplicarlo.
func take_damage(amount: float):
	if damage_timer.is_stopped() and !Signals.player_is_dead:
		var final_damage: float = amount

		# Los modificadores pueden reducir el daño recibido
		for modifier in inventory.get_modifiers():
			if modifier.has_method("modify_incoming_damage"):
				final_damage = modifier.modify_incoming_damage(final_damage)

		# Algunos modificadores pueden bloquear el daño completamente
		for modifier in inventory.modifiers:
			if modifier.has_method("avoid_damage"):
				if modifier.avoid_damage():
					damage_timer.start(stats.get_invulnerability_time())
					await damage_timer.timeout
					_check_overlapping_enemies()
					_check_overlapping_tramps()
					return

		# Aplica el daño: sacude la cámara, reproduce audio, descuenta salud y activa i-frames
		camera.shake(1.0)
		audio.play_damage()
		stats.take_damage(final_damage)
		animation.player_taking_damage()
		damage_timer.start(stats.get_invulnerability_time())
		# Desactiva la máscara de colisión con enemigos durante la invulnerabilidad
		set_collision_mask_value(4, false)
		await damage_timer.timeout
		set_collision_mask_value(4, true)
		# Pequeña espera extra antes de recomprobar solapamientos
		await get_tree().create_timer(0.25).timeout
		_check_overlapping_enemies()
		_check_overlapping_tramps()


# =============================================================================
# MUERTE Y REVIVE
# =============================================================================

# Oculta las armas al morir.
func player_death():
	weapon_holder.hide()

# Al mostrar el menú de muerte, libera todas las habilidades activas del jugador.
func _on_show_death_menu():
	if abilities and abilities.abilities.size() > 0:
		for ability in abilities.abilities:
			if is_instance_valid(ability):
				ability.queue_free()

# Muestra las armas, activa la animación de daño temporal y comprueba solapamientos al revivir.
func player_revive():
	weapon_holder.show()
	animation.player_taking_damage()
	damage_timer.start(stats.get_invulnerability_time())
	await damage_timer.timeout

	await get_tree().create_timer(0.25).timeout

	_check_overlapping_enemies()


# =============================================================================
# KNOCKBACK
# =============================================================================

# Aplica empuje al personaje solo si no está en periodo de invulnerabilidad.
func apply_knockback(dir: Vector2, force: float, duration: float = 0.2):
	if damage_timer.is_stopped():
		movement.apply_knockback(dir, force, duration)


# =============================================================================
# DAÑO DE TRAMPAS
# =============================================================================

# Aplica el daño de una trampa al jugador, respetando modificadores que puedan evitarlo.
func take_tramp_damage(body):
	if body.has_method("do_damage"):
		for modifier in inventory.modifiers:
			if modifier.has_method("avoid_tramp_damage"):
				if modifier.avoid_tramp_damage():
					return
	body.do_damage(tramp_detector_area)

# Callback del área de trampas: aplica daño si el cuerpo es una trampa.
func _on_tramp_detector_area_entered(body):
	if body.is_in_group("trap"):
		take_tramp_damage(body)


# =============================================================================
# COMPROBACIÓN DE SOLAPAMIENTOS TRAS INVULNERABILIDAD
# =============================================================================

# Comprueba si el jugador sigue solapando con algún enemigo y aplica daño si es así.
func _check_overlapping_enemies():
	var overlapping_bodies = detector_area.get_overlapping_areas()
	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			body.get_parent().do_damage(self)
			return

# Comprueba si el jugador sigue solapando con alguna trampa y aplica daño si es así.
func _check_overlapping_tramps():
	var overlapping_tramps = tramp_detector_area.get_overlapping_areas()
	for body in overlapping_tramps:
		if body.is_in_group("trap"):
			take_tramp_damage(body)


# =============================================================================
# UTILIDADES Y MODIFICADORES DE ESTADO
# =============================================================================

# Devuelve el componente de stats del personaje.
func get_stats() -> CharacterStats:
	return stats

# Desactiva la detección de trampas (usada por ítems que otorgan inmunidad).
func set_tramp_inmunity():
	tramp_detector_area.set_collision_mask_value(2, false)

# Activa el modo vuelo: desactiva la colisión con obstáculos de suelo y con trampas.
func set_flying():
	set_collision_mask_value(6, false)
	set_tramp_inmunity()

# Permite manipular el estado de daño desde fuera del componente (p.ej. ítems o habilidades).
func change_player_damagable_timer(state: bool, _timer: float):
	if state and damage_timer.is_stopped():
		_check_overlapping_enemies()
	else:
		damage_timer.start(stats.get_invulnerability_time())
		await damage_timer.timeout
		_check_overlapping_enemies()

# Devuelve true si el jugador puede recibir daño (el timer de invulnerabilidad está parado).
func is_player_damagable():
	return damage_timer.is_stopped()


# =============================================================================
# -------REMOVE------------- (debug / god mode)
# =============================================================================

# Modo dios para pruebas: infla todas las stats al máximo. ELIMINAR.
func god_mode():
	if Input.is_action_just_pressed("god_mode"):
		print("eres dios")
		stats.extra_damage = 99
		stats.invulnerability_time = 99
		stats.speed += 100
		stats.extra_lifetime = 100
		stats.max_health = 99999
		stats.heal(999999999)

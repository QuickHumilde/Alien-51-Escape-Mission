extends Node
class_name EffectController

# =============================================================================
# ESTRUCTURAS DE DATOS
# =============================================================================

# Diccionario de efectos activos: id → runtime
# Cada runtime tiene la forma:
# {
#   "effect":    StatusEffect,  <- instancia del efecto
#   "time_left": float,         <- segundos restantes
#   "stacks":    int            <- número de stacks acumulados
# }
var _active: Dictionary = {}

# Diccionario de bloqueos de re-aplicación: id → time_left (segundos)
# Mientras el tiempo sea > 0, ese tipo de efecto no puede reaplicarse.
var _lockouts: Dictionary = {}

# Nodo al que pertenece este controlador (el enemigo o entidad afectada)
var target: Node = null


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func init(_target: Node) -> void:
	target = _target


# =============================================================================
# APLICACIÓN DE EFECTOS
# =============================================================================

# Aplica un efecto de estado al target. Gestiona lockouts, stacks y modos
# de apilado (REFRESH, REPLACE, STACK) según la configuración del efecto.
func add_effect(effect: StatusEffect) -> void:
	if effect == null:
		return
	if target == null or not is_instance_valid(target):
		return

	var id := effect.id
	if id.is_empty():
		return

	# Si el efecto está en período de lockout, no se puede reaplicar
	if float(_lockouts.get(id, 0.0)) > 0.0:
		return

	# Primera aplicación: registra el efecto y llama a on_apply
	if not _active.has(id):
		_active[id] = {
			"effect": effect,
			"time_left": effect.duration,
			"stacks": 1
		}
		effect.on_apply(target)
		if effect.reapply_lockout > 0.0:
			_lockouts[id] = effect.reapply_lockout
		return

	# El efecto ya existe: actualiza según el modo de apilado
	var runtime := _active[id] as Dictionary
	var mode: int = int(effect.stacking_mode)
	match mode:
		StatusEffect.StackingMode.REFRESH:
			# Toma el mayor tiempo entre el actual y el nuevo (no reduce duración)
			runtime["time_left"] = max(float(runtime["time_left"]), effect.duration)
		StatusEffect.StackingMode.REPLACE:
			# Elimina el efecto anterior y aplica el nuevo desde cero
			var old_effect: StatusEffect = runtime["effect"]
			if old_effect != null:
				old_effect.on_remove(target)
			runtime["effect"] = effect
			runtime["time_left"] = effect.duration
			runtime["stacks"] = 1
			effect.on_apply(target)
		StatusEffect.StackingMode.STACK:
			# Añade un stack y refresca el tiempo si el nuevo es mayor
			runtime["stacks"] = int(runtime.get("stacks", 1)) + 1
			runtime["time_left"] = max(float(runtime["time_left"]), effect.duration)

	_active[id] = runtime

	# Activa o reinicia el lockout de re-aplicación
	if effect.reapply_lockout > 0.0:
		_lockouts[id] = effect.reapply_lockout


# =============================================================================
# CONSULTA Y ELIMINACIÓN DE EFECTOS
# =============================================================================

# Devuelve true si hay un efecto activo con el ID indicado.
func has_effect(id: String) -> bool:
	return _active.has(id)

# Elimina un efecto activo por ID y llama a su on_remove si el target es válido.
func remove_effect(id: String) -> void:
	if not _active.has(id):
		return
	if target == null or not is_instance_valid(target):
		_active.erase(id)
		return
	var runtime := _active[id] as Dictionary
	var effect: StatusEffect = runtime.get("effect")
	if effect != null:
		effect.on_remove(target)
	_active.erase(id)


# =============================================================================
# ACTUALIZACIÓN POR FRAME
# =============================================================================

# Descuenta el tiempo restante de cada efecto y lockout activo.
# Elimina los que han expirado llamando a remove_effect (que llama on_remove).
func _process(delta: float) -> void:
	# Tick de efectos activos
	if not _active.is_empty():
		var to_remove: Array[String] = []
		for id in _active.keys():
			var runtime := _active[id] as Dictionary
			var t := float(runtime.get("time_left", 0.0)) - delta
			runtime["time_left"] = t
			_active[id] = runtime
			if t <= 0.0:
				to_remove.append(str(id))
		for id in to_remove:
			remove_effect(id)

	# Tick de lockouts: se limpian al expirar
	if not _lockouts.is_empty():
		var to_clear: Array[String] = []
		for id in _lockouts.keys():
			var t := float(_lockouts[id]) - delta
			if t <= 0.0:
				to_clear.append(str(id))
			else:
				_lockouts[id] = t
		for id in to_clear:
			_lockouts.erase(id)


# =============================================================================
# CONSULTAS DE STATS MODIFICADAS
# =============================================================================

# Devuelve el multiplicador de velocidad resultante de todos los SlowEffect activos.
# Toma el valor más restrictivo (mínimo) entre todos los slows aplicados.
func get_speed_multiplier() -> float:
	var mult := 1.0
	for id in _active.keys():
		var runtime := _active[id] as Dictionary
		var effect: StatusEffect = runtime.get("effect")
		if effect is SlowEffect:
			mult = min(mult, (effect as SlowEffect).multiplier)
	return mult

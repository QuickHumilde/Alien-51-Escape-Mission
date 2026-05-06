extends Node
class_name EffectController

# id -> runtime data
# runtime = {
#   "effect": StatusEffect,
#   "time_left": float,
#   "stacks": int
# }
var _active: Dictionary = {}

# NUEVO: id -> time_left (bloqueo de re-aplicar ese id)
var _lockouts: Dictionary = {}

var target: Node = null

func init(_target: Node) -> void:
	target = _target

func add_effect(effect: StatusEffect) -> void:
	if effect == null:
		return
	if target == null or not is_instance_valid(target):
		return

	var id := effect.id
	if id.is_empty():
		return

	# NUEVO: si está en lockout, no permitir reaplicar este tipo
	if float(_lockouts.get(id, 0.0)) > 0.0:
		return

	if not _active.has(id):
		_active[id] = {
			"effect": effect,
			"time_left": effect.duration,
			"stacks": 1
		}
		effect.on_apply(target)

		# NUEVO: arrancar lockout al aplicar
		if effect.reapply_lockout > 0.0:
			_lockouts[id] = effect.reapply_lockout
		return

	var runtime := _active[id] as Dictionary
	var mode: int = int(effect.stacking_mode)

	match mode:
		StatusEffect.StackingMode.REFRESH:
			runtime["time_left"] = max(float(runtime["time_left"]), effect.duration)

		StatusEffect.StackingMode.REPLACE:
			var old_effect: StatusEffect = runtime["effect"]
			if old_effect != null:
				old_effect.on_remove(target)
			runtime["effect"] = effect
			runtime["time_left"] = effect.duration
			runtime["stacks"] = 1
			effect.on_apply(target)

		StatusEffect.StackingMode.STACK:
			runtime["stacks"] = int(runtime.get("stacks", 1)) + 1
			runtime["time_left"] = max(float(runtime["time_left"]), effect.duration)

	_active[id] = runtime

	# NUEVO: arrancar lockout también cuando se actualiza/reemplaza/stackea
	if effect.reapply_lockout > 0.0:
		_lockouts[id] = effect.reapply_lockout

func has_effect(id: String) -> bool:
	return _active.has(id)

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

func _process(delta: float) -> void:
	# Actualizar efectos activos
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

func get_speed_multiplier() -> float:
	var mult := 1.0
	for id in _active.keys():
		var runtime := _active[id] as Dictionary
		var effect: StatusEffect = runtime.get("effect")
		if effect is SlowEffect:
			mult = min(mult, (effect as SlowEffect).multiplier)
	return mult

extends Node
class_name SummerChairAbility

# Señales para sincronizar la barra de usos del HUD
# (se reutiliza el sistema de cooldown para mostrar los usos restantes)
signal cooldown_started(duration: float)
signal cooldown_progress(progress: float)
signal cooldown_finished()


# =============================================================================
# PARÁMETROS Y ESTADO
# =============================================================================

# Número máximo de usos disponibles
@export var max_uses: int = 3
# Usos restantes en la sesión actual
var uses_left: int = 3
# Referencia al jugador propietario de esta habilidad
var player: Character = null


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

# Permite pasar los usos restantes al instanciar (usado al recoger un ítem soltado).
# El valor por defecto especial -99999 indica que no se sobreescribe uses_left.
func _init(uses: int = -99999):
	if uses != -99999:
		uses_left = uses

# Asigna el jugador y sincroniza el HUD con el estado actual de usos.
func get_player(body: Character) -> void:
	player = body
	if uses_left <= 0:
		uses_left = max_uses
	uses_left = clamp(uses_left, 0, max_uses)
	emit_signal("cooldown_started", 0.0)
	_emit_uses_progress()


# =============================================================================
# ACTIVACIÓN
# =============================================================================

# Consume un uso para curar al jugador. Si se agotan los usos, elimina la habilidad.
func activate_with_player(_player: Character) -> void:
	if player == null or not is_instance_valid(player):
		player = _player
	if player == null or not is_instance_valid(player):
		return
	if uses_left <= 0:
		return

	var health: float = player_health_calcs()
	player.stats.heal(health)
	uses_left -= 1
	_play_sound()
	_emit_uses_progress()

	# Si se agotaron los usos, notifica al HUD y se autodestruye
	if uses_left <= 0:
		emit_signal("cooldown_finished")
		player.abilities.remove_current_ability()
		queue_free()


# =============================================================================
# HUD DE USOS
# =============================================================================

# Emite cooldown_progress con el ratio de usos restantes sobre el máximo
# para que la barra del HUD refleje cuántos usos quedan.
func _emit_uses_progress() -> void:
	var denom = max(1, max_uses)
	var progress := float(uses_left) / float(denom)
	emit_signal("cooldown_progress", progress)

# Recarga los usos al máximo y actualiza el HUD.
func refill_uses() -> void:
	uses_left = max_uses
	emit_signal("cooldown_started", 0.0)
	_emit_uses_progress()


# =============================================================================
# CAMBIO DE HABILIDAD
# =============================================================================

# Al cambiar de habilidad, suelta el ítem físico en el mundo con los usos restantes
# conservados, y destruye este nodo.
func change_ability(new_ability_position):
	var item_scene: PackedScene = load("res://scenes/items/summer_chair_ability_item.tscn")
	var inst = item_scene.instantiate()
	inst.change_uses(uses_left)
	player.get_tree().current_scene.add_child(inst)
	inst.global_position = new_ability_position
	inst.disable_pickup(2.0)
	queue_free()


# =============================================================================
# CÁLCULO DE CURACIÓN
# =============================================================================

# Devuelve la cantidad de salud a restaurar: 2/3 de la salud máxima del jugador.
func player_health_calcs():
	var max_health: float = player.stats.get_max_health()
	return max_health * 2.0 / 3.0


# =============================================================================
# AUDIO
# =============================================================================

# Reproduce el SFX de la silla con pitch aleatorio leve.
func _play_sound() -> void:
	var pitch: float = randf_range(0.95, 1.1)
	AudioManager.play_sfx("oars_on_water", -5.0, pitch)


# =============================================================================
# GUARDADO Y CARGA
# =============================================================================

# Serializa el número de usos para el sistema de save.
func get_save_state() -> Dictionary:
	return {
		"uses_left": uses_left,
		"max_uses": max_uses
	}

# Restaura los usos desde un save y sincroniza el HUD.
# Si los usos ya estaban agotados, emite cooldown_finished.
func load_save_state(state: Dictionary) -> void:
	max_uses = int(state.get("max_uses", max_uses))
	uses_left = int(state.get("uses_left", uses_left))
	uses_left = clamp(uses_left, 0, max_uses)
	emit_signal("cooldown_started", 0.0)
	_emit_uses_progress()
	if uses_left <= 0:
		emit_signal("cooldown_finished")


# =============================================================================
# UTILIDADES
# =============================================================================

# Devuelve la ruta de la textura del icono para el HUD.
func get_icon_path() -> String:
	return "res://assets/sprites/items/SummerChairItem.png"

# Fuerza la sincronización del HUD con el estado actual de usos.
# Útil al equipar la habilidad desde un save o al cambiar de sala.
func sync_hud() -> void:
	emit_signal("cooldown_started", 0.0)
	_emit_uses_progress()
	if uses_left <= 0:
		emit_signal("cooldown_finished")

extends Node
class_name CharacterAbilities

# =============================================================================
# VARIABLES DE ESTADO
# =============================================================================

# Lista de habilidades activas del jugador (normalmente contiene solo una)
var abilities: Array = []
# Índice de la habilidad actualmente seleccionada dentro del array
var actual_ability_index: int = 0
# Referencia al cuerpo del jugador para pasarlo a las habilidades que lo necesiten
var player: Character


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func init(player_body: Character) -> void:
	player = player_body


# =============================================================================
# INPUT
# =============================================================================

# Detecta la acción "ability" y activa la habilidad actual.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ability"):
		use_ability()


# =============================================================================
# ACTIVACIÓN DE HABILIDAD
# =============================================================================

# Recorre todas las habilidades del array y las activa.
# Soporta habilidades como PackedScene (las instancia en la escena actual)
# y como nodos ya existentes (llama directamente a activate o activate_with_player).
func use_ability():
	for ability in abilities:
		if ability is PackedScene:
			var instance = ability.instantiate()
			player.get_tree().current_scene.add_child(instance)
			if instance.has_method("activate"):
				instance.activate()
			elif instance.has_method("activate_with_player"):
				instance.activate_with_player(player)

		if ability.has_method("activate"):
			ability.activate()
		if ability.has_method("activate_with_player"):
			ability.activate_with_player(player)


# =============================================================================
# GESTIÓN DE HABILIDADES
# =============================================================================

# Reemplaza la habilidad activa por una nueva.
# Si drop_old es true, notifica a la anterior para que gestione su drop en el mundo.
# Actualiza el HUD con el icono y el estado de carga de la nueva habilidad.
func change_ability(new_ability, ability_position, drop_old: bool = true):
	if drop_old and !abilities.is_empty():
		abilities[actual_ability_index].call_deferred("change_ability", ability_position)
	abilities.clear()
	abilities.append(new_ability)
	actual_ability_index = 0
	var hud := player.get_node_or_null("HUD/AbilityChargeBar")
	if hud != null:
		hud.connect_ability(new_ability)
		if new_ability != null and is_instance_valid(new_ability) and new_ability.has_method("get_icon_path"):
			hud.on_ability_pick(new_ability.get_icon_path())
		if new_ability != null and is_instance_valid(new_ability) and new_ability.has_method("sync_hud"):
			new_ability.call("sync_hud")

# Elimina una habilidad concreta del array y libera su nodo si es válido.
func remove_ability(ability):
	if ability in abilities:
		abilities.erase(ability)
		if is_instance_valid(ability) and ability is Node:
			ability.queue_free()

# Elimina la habilidad actualmente seleccionada.
func remove_current_ability():
	if abilities.is_empty():
		return
	var ability = abilities[actual_ability_index]
	remove_ability(ability)

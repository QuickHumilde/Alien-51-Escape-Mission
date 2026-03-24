extends Node
class_name CharacterAbilities

var abilities : Array = []
var actual_ability_index : int = 0
var player : Character

func init(player_body : Character) -> void:
	player = player_body

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ability"):
		use_ability()

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
		
func change_ability(new_ability):
	abilities.clear()
	abilities.append(new_ability)

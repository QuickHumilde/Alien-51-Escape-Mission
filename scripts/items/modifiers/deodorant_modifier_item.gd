extends ItemModifier
class_name DeodorantModifierItem

var player: Character
var deodorant_scent_scene: PackedScene = preload("res://scenes/extras/deodorant_scent_scene.tscn")

func _init(body: Character) -> void:
	player = body
	call_deferred("put_deodorant_on_alien")

func get_bonus(stat_name: String, _player: CharacterStats):
	match stat_name:
		_:
			return 0.0

func put_deodorant_on_alien():
	var inst = deodorant_scent_scene.instantiate()
	player.add_child(inst)
	inst.global_position = player.global_position

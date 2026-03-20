extends ItemModifier
class_name FootballBallModifierItem

const FOOTBALL_BALL_SCENE: PackedScene = preload("res://scenes/extras/football_ball.tscn")
var player: Character
var inst: Node2D = null

func _init(body: Character) -> void:
	player = body
	Signals.room_changed.connect(_on_room_changed)

func get_bonus(stat_name: String, _player: CharacterStats):
	match stat_name:
		_:
			return 0.0

func _on_room_changed(_room_type: String) -> void:
	destroy()
	create_instance()

func create_instance() -> void:
	inst = FOOTBALL_BALL_SCENE.instantiate()
	inst.modify_damage(player.stats.get_damage())
	inst.global_position = player.global_position

	var parent := player.get_parent()
	if parent == null:
		return
	
	parent.add_child(inst)

func destroy() -> void:
	if inst != null and is_instance_valid(inst):
		inst.queue_free()
	inst = null

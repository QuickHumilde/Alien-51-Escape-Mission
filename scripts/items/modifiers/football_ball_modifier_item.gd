extends ItemModifier
class_name FootballBallModifierItem

const FOOTBALL_BALL_SCENE: PackedScene = preload("res://scenes/extras/football_ball.tscn")

var player: Character
var inst: Node2D = null

func _init(body: Character) -> void:
	player = body
	if not Signals.room_changed.is_connected(_on_room_changed):
		Signals.room_changed.connect(_on_room_changed)

func _on_room_changed(_room_type: String) -> void:
	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		destroy()
		_disconnect_signals()
		return

	destroy()
	create_instance()

func create_instance() -> void:
	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		return
	if player.stats == null or not is_instance_valid(player.stats):
		return

	inst = FOOTBALL_BALL_SCENE.instantiate()
	if inst == null:
		return

	inst.modify_damage(player.stats.get_damage())
	inst.global_position = player.global_position

	var parent := player.get_parent()
	if parent == null or not is_instance_valid(parent):
		inst.queue_free()
		inst = null
		return

	parent.add_child(inst)

func destroy() -> void:
	if inst != null and is_instance_valid(inst):
		inst.queue_free()
	inst = null

func _disconnect_signals() -> void:
	if Signals.room_changed.is_connected(_on_room_changed):
		Signals.room_changed.disconnect(_on_room_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		destroy()
		_disconnect_signals()

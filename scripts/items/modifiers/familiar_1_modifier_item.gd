extends ItemModifier
class_name FamiliarModifierItem

const FAMILIAR_SCENE: PackedScene = preload("res://scenes/familiars/familiar_1.tscn")
const FAMILIAR_BULLET_SCENE: PackedScene = preload("res://scenes/bullets/spit_bullet.tscn")

var player: Character
var inst: Node2D = null

var shoot_interval: float = 1.5
var target_range: float = 100.0
var bullet_speed: float = 100.0
var bullet_lifetime: float = 0.75
var bullet_knockback: float = 120.0

func _init(body: Character) -> void:
	player = body
	Signals.room_changed.connect(_on_room_changed)
	create_instance()

func get_bonus(stat_name: String, _player: CharacterStats):
	match stat_name:
		_:
			return 0.0

func _on_room_changed(_room_type: String) -> void:
	destroy()
	create_instance()

func create_instance() -> void:
	if player == null or not is_instance_valid(player):
		return

	inst = FAMILIAR_SCENE.instantiate()
	inst.global_position = player.global_position

	var parent := player.get_parent()
	if parent == null:
		return
	parent.add_child(inst)

	if inst.has_method("init"):
		inst.init(player)

	if inst.has_method("configure"):
		inst.configure({
			"bullet_scene": FAMILIAR_BULLET_SCENE,
			"shoot_interval": shoot_interval,
			"target_range": target_range,
			"bullet_damage": 0.5 + player.stats.get_damage(),
			"bullet_speed": bullet_speed,
			"bullet_lifetime": bullet_lifetime,
			"bullet_knockback": bullet_knockback
		})

func destroy() -> void:
	if inst != null and is_instance_valid(inst):
		inst.queue_free()
	inst = null

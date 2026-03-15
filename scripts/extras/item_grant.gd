extends Area2D
class_name ItemPickup

@export var item_id: int = -1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if item_id < 0:
		return
	if body == null or not body.is_in_group("player"):
		return

	var combat := body.get_node_or_null("CharacterCombat") as CharacterCombat

	ItemManager.mark_removed(item_id)

	if ItemManager.is_weapon_item(item_id):
		if combat != null:
			var weapon_id := ItemManager.get_weapon_id_from_item(item_id)
			if weapon_id >= 0:
				combat.add_weapon(weapon_id)
		queue_free()
		return

	var scene := ItemManager.get_scene(item_id)
	if scene != null:
		var inst := scene.instantiate()
		body.add_child(inst)

	queue_free()

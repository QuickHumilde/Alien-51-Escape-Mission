extends Area2D

@export var dir: String = "right"
@export var cooldown: float = 0.25
var locked := false

func reset_lock() -> void:
	locked = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	locked = false

func _on_body_entered(body: Node) -> void:
	if locked:
		return
	if not body.is_in_group("player"):
		return

	locked = true

	var room := _find_room_node()

	if room != null and room.has_signal("door_entered"):
		room.emit_signal("door_entered", dir)

	await get_tree().create_timer(cooldown).timeout
	locked = false

func _find_room_node() -> Node:
	# 1) owner suele ser el root de la escena instanciada (la sala)
	if owner != null and owner.has_signal("door_entered"):
		return owner

	# 2) fallback: subir en el árbol hasta encontrar quien tenga la señal
	var n: Node = self
	while n != null:
		if n.has_signal("door_entered"):
			return n
		n = n.get_parent()

	return null

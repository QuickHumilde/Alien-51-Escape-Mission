extends Node2D

signal door_entered(dir: String)

# Capacidades de la plantilla (EDITABLE en cada escena):
# Ej: si esta sala nunca puede tener puerta izquierda -> left=false
@export var door_caps := { "up": true, "down": true, "left": true, "right": true }

var doors: Node = null
var spawns: Node = null

func _enter_tree() -> void:
	doors = get_node_or_null("Doors")
	spawns = get_node_or_null("Spawns")

func get_door_caps() -> Dictionary:
	return {
		"up": bool(door_caps.get("up", true)),
		"down": bool(door_caps.get("down", true)),
		"left": bool(door_caps.get("left", true)),
		"right": bool(door_caps.get("right", true)),
	}

func setup(room_data: Dictionary) -> void:
	if doors == null:
		doors = get_node_or_null("Doors")
	if spawns == null:
		spawns = get_node_or_null("Spawns")

	if doors == null:
		return

	_set_door_enabled("Up", "up", room_data)
	_set_door_enabled("Down", "down", room_data)
	_set_door_enabled("Left", "left", room_data)
	_set_door_enabled("Right", "right", room_data)

func _set_door_enabled(node_name: String, key: String, room_data: Dictionary) -> void:
	var door_node := doors.get_node_or_null(node_name)
	if door_node == null:
		return

	# IMPORTANTE: el mapa dice si hay conexión, y la plantilla dice si esa puerta es posible
	var enabled: bool = bool(room_data.get("doors", {}).get(key, false)) and bool(door_caps.get(key, true))

	var a := door_node as Area2D
	if a == null:
		return

	a.set_deferred("monitoring", enabled)
	a.set_deferred("monitorable", enabled)

	# Desactivar colisión también (para que quede “muerta” totalmente)
	var shape := a.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", not enabled)

	# Rearmar el script de la puerta (por si venía bloqueada)
	if a.has_method("reset_lock"):
		a.call("reset_lock")

	# si luego metes sprites, aquí puedes: door_node.visible = enabled
	a.visible = false

func get_center_global() -> Vector2:
	if spawns == null:
		spawns = get_node_or_null("Spawns")
	if spawns != null:
		var c := spawns.get_node_or_null("Center") as Node2D
		if c != null:
			return c.global_position
	return global_position

func get_spawn_global(entered_from_dir: String) -> Vector2:
	if spawns == null:
		spawns = get_node_or_null("Spawns")
	if spawns == null:
		return global_position

	var spawn_name := "Center"
	match entered_from_dir:
		"up": spawn_name = "FromUp"
		"down": spawn_name = "FromDown"
		"left": spawn_name = "FromLeft"
		"right": spawn_name = "FromRight"
		_: spawn_name = "Center"

	var m := spawns.get_node_or_null(spawn_name) as Node2D
	if m != null:
		return m.global_position

	var c := spawns.get_node_or_null("Center") as Node2D
	if c != null:
		return c.global_position

	return global_position

extends Node2D

signal door_entered(dir: String)

@export var door_caps := { "up": true, "down": true, "left": true, "right": true }
@export var lock_doors_until_clear: bool = true
@export var enemies_node_path: NodePath = NodePath("Enemies")
@export var cleared: bool = false

var doors: Node = null
var spawns: Node = null
var enemies_root: Node = null

var _enemies_alive: int = 0
var _cleared: bool = true
var _enemy_signals_connected: bool = false

func _enter_tree() -> void:
	doors = get_node_or_null("Doors")
	spawns = get_node_or_null("Spawns")
	enemies_root = get_node_or_null(enemies_node_path)

func _ready() -> void:
	call_deferred("_recount_enemies_and_update_doors")

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
	if enemies_root == null:
		enemies_root = get_node_or_null(enemies_node_path)


	if doors == null:
		return

	_set_door_enabled("Up", "up", room_data)
	_set_door_enabled("Down", "down", room_data)
	_set_door_enabled("Left", "left", room_data)
	_set_door_enabled("Right", "right", room_data)

	_connect_doors_to_room_signal()

	if lock_doors_until_clear:
		_connect_enemy_signals_if_possible()
		call_deferred("_recount_enemies_and_update_doors")
	else:
		_set_all_doors_open(true)

# ----------------- Door wrapper -> Room signal -----------------

func _connect_doors_to_room_signal() -> void:
	if doors == null:
		return

	var cb := Callable(self, "_on_door_wrapper_entered")
	_connect_doors_recursive(doors, cb)

func _connect_doors_recursive(n: Node, cb: Callable) -> void:
	for c in n.get_children():
		if c == null:
			continue
		if c.has_signal("entered"):
			if not c.is_connected("entered", cb):
				c.connect("entered", cb)
		_connect_doors_recursive(c, cb)

func _on_door_wrapper_entered(dir: String) -> void:
	emit_signal("door_entered", dir)

# ----------------- Enable doors based on map -----------------

func _set_door_enabled(node_name: String, key: String, room_data: Dictionary) -> void:
	var door_node := doors.get_node_or_null(node_name)
	if door_node == null:
		return

	var enabled: bool = bool(room_data.get("doors", {}).get(key, false)) and bool(door_caps.get(key, true))

	if door_node.has_method("set_enabled"):
		door_node.call("set_enabled", enabled)
		return

	var a := door_node as Area2D
	if a == null:
		return
	a.set_deferred("monitoring", enabled)
	a.set_deferred("monitorable", enabled)

# ----------------- Enemies -> open/close doors -----------------

func _connect_enemy_signals_if_possible() -> void:
	if _enemy_signals_connected:
		return

	if enemies_root == null:
		enemies_root = get_node_or_null(enemies_node_path)
	if enemies_root == null:
		return

	enemies_root.child_entered_tree.connect(Callable(self, "_on_enemy_child_entered"))
	enemies_root.child_exiting_tree.connect(Callable(self, "_on_enemy_child_exiting"))
	_enemy_signals_connected = true

func _recount_enemies_and_update_doors() -> void:
	if not lock_doors_until_clear:
		return

	if enemies_root == null:
		enemies_root = get_node_or_null(enemies_node_path)

	_enemies_alive = 0
	if enemies_root != null:
		var children := enemies_root.get_children()
		for c in children:
			if c == null:
				continue
			_enemies_alive += 1
	_cleared = (_enemies_alive <= 0)
	_update_doors_open_state()

func _on_enemy_child_entered(child: Node) -> void:
	if child == null:
		return
	_enemies_alive += 1
	_cleared = false
	_update_doors_open_state()

func _on_enemy_child_exiting(child: Node) -> void:
	if child == null:
		return
	_enemies_alive = max(0, _enemies_alive - 1)
	_cleared = (_enemies_alive <= 0)
	_update_doors_open_state()

func _update_doors_open_state() -> void:
	_set_all_doors_open(_cleared)

func _set_all_doors_open(open: bool) -> void:
	if doors == null:
		return

	for n in ["Up", "Down", "Left", "Right"]:
		var d := doors.get_node_or_null(n)
		if d == null:
			continue
		if d.has_method("set_open"):
			d.call("set_open", open)

# ----------------- Spawn helpers -----------------

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

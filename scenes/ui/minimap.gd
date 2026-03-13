extends Control

@export var cell_size: float = 10.0
@export var padding: float = 12.0
@export var current_inset: float = 2.0

@export var color_normal: Color = Color(0.75, 0.75, 0.75, 0.9)
@export var color_start: Color = Color(0.4, 0.9, 0.4, 0.95)
@export var color_item: Color = Color(0.3, 0.6, 1.0, 0.95)
@export var color_shop: Color = Color(1.0, 0.8, 0.2, 0.95)
@export var color_boss: Color = Color(1.0, 0.3, 0.3, 0.95)
@export var color_current: Color = Color(1.0, 1.0, 1.0, 1.0)

@export var corridor_color: Color = Color(1.0, 1.0, 1.0, 0.949)
@export var corridor_width: float = 2.0

@export var stub_len_ratio: float = 0.45
@export var stub_inset: float = 1.0

var dungeon_map: Dictionary = {}
var current_pos: Vector2 = Vector2.ZERO

var _min_x: float = 0.0
var _min_y: float = 0.0
var _origin: Vector2 = Vector2.ZERO

@export var minimap_size: Vector2 = Vector2(220, 180)

func _ready() -> void:
	pass

func set_data(m: Dictionary, cur: Vector2) -> void:
	dungeon_map = m
	current_pos = cur
	queue_redraw()

func _room_top_left(room_pos: Vector2) -> Vector2:
	return _origin + Vector2((room_pos.x - _min_x) * cell_size, (room_pos.y - _min_y) * cell_size)

func _room_center(room_pos: Vector2) -> Vector2:
	return _room_top_left(room_pos) + Vector2(cell_size * 0.5, cell_size * 0.5)

func _room_color(t: String) -> Color:
	match t:
		"start": return color_start
		"item": return color_item
		"shop": return color_shop
		"boss": return color_boss
		_: return color_normal

func _draw() -> void:
	if dungeon_map.is_empty():
		return

	# bounds
	var min_x := 999999.0
	var max_x := -999999.0
	var min_y := 999999.0
	var max_y := -999999.0

	for key in dungeon_map.keys():
		var d: Dictionary = dungeon_map[key]
		var rp: Vector2 = d.get("pos", Vector2.ZERO)
		min_x = min(min_x, rp.x)
		max_x = max(max_x, rp.x)
		min_y = min(min_y, rp.y)
		max_y = max(max_y, rp.y)

	_min_x = min_x
	_min_y = min_y

	# Centrar el minimapa en la sala actual dentro del tamaño visible del Control
	_origin = Vector2(padding, padding)
	_origin += Vector2(padding, padding) * 0.0

	# ---- 1) CONEXIONES REALES ----
	for key in dungeon_map.keys():
		var d: Dictionary = dungeon_map[key]
		var rp: Vector2 = d.get("pos", Vector2.ZERO)
		var doors: Dictionary = d.get("doors", {})

		var c := _room_center(rp)

		_draw_stub(c, doors, "up")
		_draw_stub(c, doors, "down")
		_draw_stub(c, doors, "left")
		_draw_stub(c, doors, "right")

		if doors.get("right", false) and dungeon_map.has(str(rp.x + 1.0) + "," + str(rp.y)):
			var c2 := _room_center(rp + Vector2(1, 0))
			draw_line(c, c2, corridor_color, corridor_width)

		if doors.get("down", false) and dungeon_map.has(str(rp.x) + "," + str(rp.y + 1.0)):
			var c3 := _room_center(rp + Vector2(0, 1))
			draw_line(c, c3, corridor_color, corridor_width)

	# ---- 2) SALAS ----
	for key in dungeon_map.keys():
		var d: Dictionary = dungeon_map[key]
		var rp: Vector2 = d.get("pos", Vector2.ZERO)
		var t: String = str(d.get("type", "normal"))

		var pos2 := _room_top_left(rp)
		var rect := Rect2(pos2 + Vector2(1, 1), Vector2(cell_size - 3, cell_size - 3))

		draw_rect(rect, _room_color(t), true)
		draw_rect(rect, Color(0, 0, 0, 0.6), false, 1.0)

	# ---- 3) SALA ACTUAL (MÁS PEQUEÑA) ----
	var cur_top_left := _room_top_left(current_pos) + Vector2(current_inset, current_inset)
	var cur_size := Vector2(cell_size, cell_size) - Vector2(current_inset * 2.0, current_inset * 2.0)
	var cur_rect := Rect2(cur_top_left, cur_size)

	# sombra/borde negro: usa grow muy pequeño (o 0)
	var shadow_grow := 0.5
	draw_rect(cur_rect.grow(shadow_grow), Color(0, 0, 0, 0.75), false, 2.0)

	# borde blanco exactamente del tamaño del rect (sin grow)
	draw_rect(cur_rect, color_current, false, 1.0)

func _draw_stub(center: Vector2, doors: Dictionary, dir: String) -> void:
	if not doors.get(dir, false):
		return

	var stub_len := cell_size * stub_len_ratio

	var from := center
	var to := center

	match dir:
		"up":
			from = center + Vector2(0, -stub_inset)
			to = center + Vector2(0, -stub_len)
		"down":
			from = center + Vector2(0, stub_inset)
			to = center + Vector2(0, stub_len)
		"left":
			from = center + Vector2(-stub_inset, 0)
			to = center + Vector2(-stub_len, 0)
		"right":
			from = center + Vector2(stub_inset, 0)
			to = center + Vector2(stub_len, 0)

	draw_line(from, to, corridor_color, corridor_width)

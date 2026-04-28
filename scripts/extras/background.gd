extends TileMapLayer

@onready var obstacles: Node2D = $"../Obstacles"
@export var decoration_sprites: Array[Texture2D]
@export var max_decorations_per_room: int = 3
@onready var decorations := $"../Decorations"
@onready var invisible_obstacle_scene: PackedScene = preload("res://scenes/extras/invisible_obstacle.tscn")
var decoration_variants: Dictionary

func _ready():
	fill_decoration_array()
	fill_dictionary()
	place_invisible_obstacles()
	decorate_random_tiles()

func fill_decoration_array():
	decoration_sprites = [
		load("res://assets/sprites/decorations/PaperDecoration1.png"),
		load("res://assets/sprites/decorations/FootprintDecoration1.png"),
		load("res://assets/sprites/decorations/SkullDecoration1.png"),
		load("res://assets/sprites/decorations/HoleDecoration1.png"),
	]

func fill_dictionary():
	decoration_variants = {
		"PaperDecoration1.png": {
			"rotation": { "min": 0.0, "max": 360.0 },
			"alpha": null,
			"scale": { "min": 0.7, "max": 1.0 },
		},
		"FootprintDecoration1.png": {
			"rotation": { "min": 0.0, "max": 360.0 },
			"alpha": { "min": 0.4, "max": 0.9 },
			"scale": { "min": 0.7, "max": 1.0 }
		},
		"SkullDecoration1.png": {
			"rotation": { "min": -90.0, "max": 90.0 },
			"alpha": null,
			"scale": { "min": 0.95, "max": 1 }
		},
		"HoleDecoration1.png": {
			"rotation": { "min": 0.0, "max": 360.0 },
			"alpha": { "min": 0.8, "max": 0.85 },
			"scale": { "min": 0.85, "max": 1 }
		},
	}

func decorate_random_tiles():
	var valid_tiles: Array[Vector2i] = []

	for coords in get_used_cells():
		if tile_allows_decoration(coords) and not has_obstacle(coords):
			valid_tiles.append(coords)

	valid_tiles.shuffle()

	var count = min(max_decorations_per_room, valid_tiles.size())

	for i in range(count):
		var coords := valid_tiles[i]
		decorate_tile(coords)

func tile_allows_decoration(coords: Vector2i) -> bool:
	var tile := get_cell_tile_data(coords)
	if tile == null:
		return false

	return tile.get_custom_data("can_decorate") == true

func tile_put_obstacle(coords: Vector2i) -> bool:
	var tile := get_cell_tile_data(coords)
	if tile == null:
		return false

	return tile.get_custom_data("put_obstacle") == true

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return has_obstacle(coords)

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	if not has_obstacle(coords):
		return

	var nav_poly := tile_data.get_navigation_polygon(0)
	if nav_poly != null:
		tile_data.set_navigation_polygon(0, null)
		tile_data.set_navigation_polygon(1, nav_poly)
	
func has_obstacle(coords: Vector2i) -> bool:
	for obstacle in get_tree().get_nodes_in_group("obstacle"):
		var local_pos := to_local(obstacle.global_position)
		var cell := local_to_map(local_pos)
		if cell == coords:
			return true
	return false
	
func decorate_tile(coords: Vector2i) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = decoration_sprites.pick_random()

	var sprite_name = sprite.texture.resource_path.get_file()
	var config = decoration_variants.get(sprite_name, {})

	sprite.position = map_to_local(coords)

	if config.has("rotation") and config["rotation"] != null:
		sprite.rotation_degrees = rand_range_from_dict(config["rotation"])

	if config.has("alpha") and config["alpha"] != null:
		sprite.modulate.a = rand_range_from_dict(config["alpha"])

	if config.has("scale") and config["scale"] != null:
		var s = rand_range_from_dict(config["scale"])
		sprite.scale = Vector2(s, s)

	decorations.add_child(sprite)

func place_invisible_obstacles():
	for coords in get_used_cells():
		if tile_put_obstacle(coords):
			var obs = invisible_obstacle_scene.instantiate()
			obs.position = map_to_local(coords)
			obstacles.add_child(obs)

func rand_range_from_dict(data):
	return randf_range(data["min"], data["max"])

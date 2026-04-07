extends TileMapLayer

@onready var obstacles: Node2D = $"../Obstacles"

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	for obstacle in obstacles.get_children():
		var cell := local_to_map(global_transform.affine_inverse() * obstacle.global_position)
		if cell == coords:
			return true
	return false

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	for obstacle in obstacles.get_children():
		var cell := local_to_map(global_transform.affine_inverse() * obstacle.global_position)
		if cell == coords:
			tile_data.set_navigation_polygon(0, null)

extends Node

var game_time_scale: float = 1.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
@export var seed_value: int = 0

func _ready() -> void:
	Engine.time_scale = game_time_scale
	generate_seed()

func generate_seed() -> int:
	if seed_value == 0:
		seed_value = int(Time.get_unix_time_from_system())
	rng.seed = seed_value
	return seed_value

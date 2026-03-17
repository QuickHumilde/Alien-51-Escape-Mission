extends Node

var current_floor: int = 1
var game_time_scale: float = 1.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
@export var seed_value: int = -1

func _ready() -> void:
	Engine.time_scale = game_time_scale
	Signals.show_death_menu.connect(_on_death_menu)
	generate_seed()

func reset():
	current_floor = 1
	game_time_scale = 1.0
	seed_value = -1
	generate_seed()

func generate_seed() -> int:
	if seed_value == -1:
		seed_value = int(Time.get_unix_time_from_system())
	rng.seed = seed_value
	return seed_value

func next_floor() -> void:
	current_floor += 1

func get_current_floor() -> int:
	return current_floor

func _on_death_menu():
	reset()

extends Node

var current_floor: int = 1
var game_time_scale: float = 1.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
@export var seed_value: int = -1

var used_bosses: Array[String] = []
@export var last_floor: int = 3
@export var final_boss_id: String = "boss_3"

func _ready() -> void:
	Engine.time_scale = game_time_scale
	Signals.show_death_menu.connect(_on_death_menu)
	generate_seed()

func reset():
	current_floor = 1
	game_time_scale = 1.0
	seed_value = -1
	used_bosses.clear()
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

func is_last_floor() -> bool:
	return current_floor >= last_floor

func is_boss_used(boss_id: String) -> bool:
	return boss_id in used_bosses

func mark_boss_used(boss_id: String) -> void:
	if boss_id not in used_bosses:
		used_bosses.append(boss_id)

func _on_death_menu():
	reset()

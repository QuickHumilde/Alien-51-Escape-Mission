extends Node

var rng := RandomNumberGenerator.new()

func set_seed(seed_value: int):
	rng.seed = seed_value

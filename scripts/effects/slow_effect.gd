extends StatusEffect
class_name SlowEffect

@export_range(0.05, 1.0, 0.05) var multiplier: float = 0.1

func _init() -> void:
	id = "slow"
	stacking_mode = StackingMode.REPLACE

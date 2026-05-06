extends Resource
class_name StatusEffect

enum StackingMode { REFRESH, REPLACE, STACK }

@export var id: String = "effect"
@export var duration: float = 1.0
@export var stacking_mode: StackingMode = StackingMode.REFRESH

func on_apply(_target: Node) -> void:
	pass

func on_remove(_target: Node) -> void:
	pass

extends Node2D

@onready var hitbox: Area2D = $Area2D
var used: bool = false

func _ready() -> void:
	hitbox.body_entered.connect(_on_body_enter)

func _on_body_enter(body: Node2D) -> void:
	if used:
		return
	if not body.is_in_group("player"):
		return
	
	used = true
	print("Cambio de piso")
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	call_deferred("_do_next_floor")

func _do_next_floor() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("next_floor"):
		await scene.next_floor()
	
	#await get_tree().process_frame
	#hitbox.set_deferred("monitoring", true)
	#hitbox.set_deferred("monitorable", true)
	#_used = false

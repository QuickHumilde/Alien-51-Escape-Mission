extends Node2D
class_name Staircase

@onready var hitbox: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var timer: Timer = $Timer

@export var final_staircase: bool = false

var used: bool = false
var revealed: bool = false

func _ready() -> void:
	hitbox.body_entered.connect(_on_body_enter)
	Signals.room_cleared.connect(_on_room_cleared)

	_apply_visual_state()

# --- SAVE API ---
func get_spawner_key() -> String:
	return str(get_path())

func get_save_state() -> Dictionary:
	return {
		"used": used,
		"revealed": revealed,
		"final_staircase": final_staircase,
	}

func load_save_state(state: Dictionary) -> void:
	used = bool(state.get("used", false))
	revealed = bool(state.get("revealed", false))
	final_staircase = bool(state.get("final_staircase", final_staircase))

	_apply_visual_state()

func _apply_visual_state() -> void:
	sprite.visible = revealed and not used
	shadow.visible = revealed and not used
	if final_staircase:
		sprite.frame = 1

	var enabled := revealed and not used
	hitbox.set_deferred("monitoring", enabled)
	hitbox.set_deferred("monitorable", enabled)

func _on_body_enter(body: Node2D) -> void:
	if used:
		return
	if not body.is_in_group("player"):
		return

	used = true
	_apply_visual_state()
	call_deferred("_do_next_floor")

func _on_room_cleared() -> void:
	if used:
		return
	if revealed:
		return

	revealed = true
	_apply_visual_state()

	timer.start()
	await timer.timeout

	_apply_visual_state()

func _do_next_floor() -> void:
	if !final_staircase:
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("next_floor"):
			await scene.next_floor()
	else:
		Signals.alien_escaped_area_51_win.emit()
		if SaveManager != null:
			SaveManager.clear_save()
		get_tree().change_scene_to_file("res://scenes/ui/win_screen.tscn")

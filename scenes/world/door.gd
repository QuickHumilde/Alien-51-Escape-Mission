extends Node2D
class_name Door

signal entered(dir: String)

@export var dir: String = "up"

@onready var trigger: Area2D = $Trigger
@onready var trigger_shape: CollisionShape2D = $Trigger/CollisionShape2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var wall_visual: CanvasItem = get_node_or_null("Wall/WallVisual") as CanvasItem
@onready var door_visual: CanvasItem = get_node_or_null("DoorVisual") as CanvasItem
@onready var blocker_door_shape: CollisionShape2D = get_node_or_null("BlockerDoor/CollisionShape2D") as CollisionShape2D
@onready var blocker_wall_shape: CollisionShape2D = get_node_or_null("Wall/BlockerWall/CollisionShape2D") as CollisionShape2D

var _enabled: bool = true
var _open: bool = true

func _ready() -> void:
	if trigger != null:
		trigger.body_entered.connect(_on_body_entered)

func set_enabled(v: bool) -> void:
	_enabled = v

	if wall_visual != null:
		wall_visual.visible = not v
	if door_visual != null:
		door_visual.visible = v

	if trigger != null:
		trigger.set_deferred("monitoring", v)
		trigger.set_deferred("monitorable", v)
	if trigger_shape != null:
		trigger_shape.set_deferred("disabled", not v)

	if blocker_wall_shape != null:
		blocker_wall_shape.set_deferred("disabled", v)

	if v:
		set_open(_open)
	else:
		if blocker_door_shape != null:
			blocker_door_shape.set_deferred("disabled", true)

func set_open(v: bool) -> void:
	_open = v
	if not _enabled:
		return

	if blocker_door_shape != null:
		blocker_door_shape.set_deferred("disabled", v)

	if anim != null:
		anim.play("open" if v else "close")

func _on_body_entered(body: Node) -> void:
	if not _enabled or not _open:
		return
	if body != null and body.is_in_group("player"):
		emit_signal("entered", dir)

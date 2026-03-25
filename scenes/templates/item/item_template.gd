@abstract
extends Node2D
class_name Item

@onready var hitbox: CollisionShape2D = $Detector/CollisionShape2D
@export var name_key : String
@export var desc_key : String
@export var price: int = 10
var id: int = -1
var item_texture: String

func _ready():
	_initiate_detectors()
	_initiate_animations()

func _on_hitbox_enter(_body):
	if _body.is_in_group("player"):
		give_changes(_body)

@abstract func give_changes(body: Character)

func get_id():
	return id

func destroy_on_pickup():
	Signals.item_picked.emit(get_id())
	queue_free()

func _on_hitbox_enter_description(body):
	if body.is_in_group("player"):
		show_information()

func _on_hitbox_exit_description(body):
	if body.is_in_group("player"):
		hide_information()

func get_item_name() -> String:
	return (name_key)

func get_description() -> String:
	return (desc_key)

func get_price() -> int:
	return price

func show_information():
	Signals.show_item_information.emit(get_item_name(), get_description(), item_texture)

func hide_information():
	Signals.hide_item_information.emit()

func enable_hitbox():
	hitbox.set_deferred("disabled" ,false)

func disable_hitbox():
	hitbox.set_deferred("disabled" ,true)

func _initiate_detectors():
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)
	$DescriptionDetector.body_exited.connect(_on_hitbox_exit_description)

func _initiate_animations():
	$Pedestal/AnimatedSprite2D.play("default")
	$Visual/AnimationPlayer.play("oscillate")

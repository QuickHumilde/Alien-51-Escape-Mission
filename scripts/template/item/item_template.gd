@abstract
extends Node2D
class_name Item

@export var id : int
@export var name_key : String
@export var desc_key : String

func _ready():
	_initiate_detectors()

# 1. Speed, 2. Health, 3. Scale
@abstract func _on_hitbox_enter(_body)

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

func show_information():
	Signals.show_item_information.emit(get_item_name(), get_description())

func hide_information():
	Signals.hide_item_information.emit()

func _initiate_detectors():
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)
	$DescriptionDetector.body_exited.connect(_on_hitbox_exit_description)

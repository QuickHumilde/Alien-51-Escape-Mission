@abstract
extends Node2D
class_name Item

@export var id : int
@export var name_key : String
@export var desc_key : String

func _ready():
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)
	
# 1. Speed, 2. Health, 3. Scale
@abstract func _on_hitbox_enter(_body)

@abstract func _on_hitbox_enter_description(_body)

func get_item_name() -> String:
	return tr(name_key)

func get_description() -> String:
	return tr(desc_key)

func show_description():
	print(get_item_name() + ": ")
	print(get_description())

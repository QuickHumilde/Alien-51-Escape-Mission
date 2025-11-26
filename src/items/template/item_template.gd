@abstract
extends Node2D
class_name Item

@export var id : int

func _ready():
	$Detector.body_entered.connect(_on_hitbox_enter)
	$DescriptionDetector.body_entered.connect(_on_hitbox_enter_description)
	
# 1. Speed, 2. Health, 3. Scale
@abstract func _on_hitbox_enter(_body)

@abstract func _on_hitbox_enter_description(_body)

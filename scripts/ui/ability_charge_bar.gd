extends Control

@onready var animation : AnimationPlayer = $AnimationPlayer
var first_time : bool = false

func _ready() -> void:
	hide()
	pass
	
func set_value(value: float):
	$AbilityCooldownBar.value=value

func connect_ability(ability):
	ability.cooldown_started.connect(_on_cooldown_started)
	ability.cooldown_progress.connect(_on_cooldown_progress)
	ability.cooldown_finished.connect(_on_cooldown_finished)

func _on_cooldown_started():
	$AbilityCooldownBar.max_value = 1.0
	$AbilityCooldownBar.value = 0.0
	$AbilityCooldownBar.visible = true

func _on_cooldown_progress(progress):
	$AbilityCooldownBar.value = progress

func on_ability_pick(item_texture: String):
	$AbilityCooldownBar.value = 1.0
	change_image(item_texture)
	if !first_time:
		animation.play("ability_charge_bar_spawn")

func _on_cooldown_finished():
	#$AbilityCooldownBar.value = 0.0
	pass

#To do
func change_image(item_texture: String):
	show()
	$AbilityImage.texture=load(item_texture)

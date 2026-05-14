extends Control

@onready var animation : AnimationPlayer = $AnimationPlayer
var first_time : bool = false

func _ready() -> void:
	hide()
	Signals.show_death_menu.connect(_on_death)
	
func set_value(value: float):
	$AbilityCooldownBar.value=value

func connect_ability(ability):
	if ability.cooldown_started.is_connected(_on_cooldown_started):
		ability.cooldown_started.disconnect(_on_cooldown_started)
	if ability.cooldown_progress.is_connected(_on_cooldown_progress):
		ability.cooldown_progress.disconnect(_on_cooldown_progress)
	if ability.cooldown_finished.is_connected(_on_cooldown_finished):
		ability.cooldown_finished.disconnect(_on_cooldown_finished)

	ability.cooldown_started.connect(_on_cooldown_started)
	ability.cooldown_progress.connect(_on_cooldown_progress)
	ability.cooldown_finished.connect(_on_cooldown_finished)

func _on_cooldown_started(_duration := 0.0):
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
	#$AbilityCooldownBar.visible = false
	#$AbilityImage.visible = false
	#first_time = false
	#hide()
	pass

func change_image(item_texture: String):
	show()
	$AbilityImage.texture=load(item_texture)

func _on_death():
	self.hide()

extends Control

signal back_pressed

func _ready() -> void:
	$Apply.text=tr("apply_settings")
	$Back.text=tr("back_settings")
	$AudioOptions/VBoxContainer/MasterLabel.text=tr("master_volume")
	$AudioOptions/VBoxContainer/SFXLabel.text=tr("sfx_volume")
	$AudioOptions/VBoxContainer/MusicLabel.text=tr("music_volume")
	
func _on_apply_pressed():
	AudioServer.set_bus_volume_db(0, linear_to_db($AudioOptions/VBoxContainer/MasterSlider.value))
	AudioServer.set_bus_volume_db(1, linear_to_db($AudioOptions/VBoxContainer/SFXSlider.value))
	AudioServer.set_bus_volume_db(2, linear_to_db($AudioOptions/VBoxContainer/MusicSlider.value))

func _on_back_pressed():
	emit_signal("back_pressed")
	queue_free()

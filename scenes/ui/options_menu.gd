extends Control

signal back_pressed

func _ready() -> void:
	add_to_group("localizable")
	LanguageManager.language_changed.connect(update_texts)
	update_texts()
	$AudioOptions/VBoxContainer/MasterLabel.text = tr("master_volume")
	$AudioOptions/VBoxContainer/SFXLabel.text = tr("sfx_volume")
	$AudioOptions/VBoxContainer/MusicLabel.text = tr("music_volume")
	$AudioOptions/VBoxContainer/MasterSlider.value = UserSettings.volume_master
	$AudioOptions/VBoxContainer/SFXSlider.value = UserSettings.volume_sfx
	$AudioOptions/VBoxContainer/MusicSlider.value = UserSettings.volume_music

func update_texts():
	$Apply.text = tr("apply_settings")
	$Back.text = tr("menu_back")

func _on_apply_pressed():
	var master = $AudioOptions/VBoxContainer/MasterSlider.value
	var sfx = $AudioOptions/VBoxContainer/SFXSlider.value
	var music = $AudioOptions/VBoxContainer/MusicSlider.value

	AudioServer.set_bus_volume_db(0, linear_to_db(master))
	AudioServer.set_bus_volume_db(1, linear_to_db(sfx))
	AudioServer.set_bus_volume_db(2, linear_to_db(music))

	UserSettings.set_all_volumes(master, music, sfx)
	UserSettings.save_settings()

	if has_node("LangDropdown"):
		var lang = $LangDropdown.selected_language_cod
		UserSettings.set_language(lang)
		UserSettings.save_settings()

func _on_back_pressed():
	emit_signal("back_pressed")
	queue_free()

extends Node

const SETTINGS_PATH = "user://settings.json"

var language: String = "en"
var volume_master: float = 1.0
var volume_music: float = 1.0
var volume_sfx: float = 1.0

func _ready():
	load_settings()
	apply_all()

func save_settings():
	var data = {
		"language": language,
		"volume_master": volume_master,
		"volume_music": volume_music,
		"volume_sfx": volume_sfx
	}
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_settings():
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if typeof(data) == TYPE_DICTIONARY:
				language = data.get("language", language)
				volume_master = data.get("volume_master", volume_master)
				volume_music = data.get("volume_music", volume_music)
				volume_sfx = data.get("volume_sfx", volume_sfx)

func apply_all():
	set_language(language)
	set_all_volumes(volume_master, volume_music, volume_sfx)

func set_language(new_lang: String):
	language = new_lang
	TranslationServer.set_locale(language)

func set_all_volumes(master: float, music: float, sfx: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(master))
	AudioServer.set_bus_volume_db(1, linear_to_db(sfx))
	AudioServer.set_bus_volume_db(2, linear_to_db(music))
	volume_master = master
	volume_music = music
	volume_sfx = sfx

func set_volume_master(val: float):
	set_all_volumes(val, volume_music, volume_sfx)

func set_volume_music(val: float):
	set_all_volumes(volume_master, val, volume_sfx)

func set_volume_sfx(val: float):
	set_all_volumes(volume_master, volume_music, val)

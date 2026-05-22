extends Node

# =============================================================================
# CONSTANTES Y VARIABLES DE CONFIGURACIÓN
# =============================================================================

# Ruta del archivo de ajustes en el directorio de usuario
const SETTINGS_PATH = "user://settings.json"

# Valores por defecto de los ajustes (se sobreescriben al cargar el archivo)
var language: String = "en"
var volume_master: float = 1.0
var volume_music: float = 1.0
var volume_sfx: float = 1.0


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready():
	# Carga los ajustes guardados y los aplica inmediatamente al arrancar
	load_settings()
	apply_all()


# =============================================================================
# GUARDADO Y CARGA DE AJUSTES
# =============================================================================

# Serializa los ajustes actuales y los escribe en disco como JSON.
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

# Lee el archivo de ajustes y restaura los valores guardados.
# Si el archivo no existe o está corrupto, mantiene los valores por defecto.
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


# =============================================================================
# APLICACIÓN DE AJUSTES
# =============================================================================

# Aplica todos los ajustes cargados al motor (idioma y volúmenes).
func apply_all():
	set_language(language)
	set_all_volumes(volume_master, volume_music, volume_sfx)


# =============================================================================
# IDIOMA
# =============================================================================

# Cambia el idioma del juego, lo propaga al TranslationServer y al LanguageManager
# (si existe en el árbol), y guarda los ajustes.
func set_language(new_lang: String):
	language = new_lang
	TranslationServer.set_locale(language)
	save_settings()
	if has_node("/root/LanguageManager"):
		get_node("/root/LanguageManager").set_language(language)


# =============================================================================
# VOLÚMENES
# =============================================================================

# Aplica los tres volúmenes al AudioServer (en dB) y actualiza las variables internas.
# Los índices de bus son: 0 = Master, 1 = SFX, 2 = Music.
func set_all_volumes(master: float, music: float, sfx: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(master))
	AudioServer.set_bus_volume_db(1, linear_to_db(sfx))
	AudioServer.set_bus_volume_db(2, linear_to_db(music))
	volume_master = master
	volume_music = music
	volume_sfx = sfx

# Cambia solo el volumen maestro manteniendo los demás.
func set_volume_master(val: float):
	set_all_volumes(val, volume_music, volume_sfx)

# Cambia solo el volumen de música manteniendo los demás.
func set_volume_music(val: float):
	set_all_volumes(volume_master, val, volume_sfx)

# Cambia solo el volumen de SFX manteniendo los demás.
func set_volume_sfx(val: float):
	set_all_volumes(volume_master, volume_music, val)

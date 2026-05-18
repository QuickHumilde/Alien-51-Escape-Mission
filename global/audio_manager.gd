extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var in_shop: bool = false
var _shop_override_active: bool = false
var _floor_paused_pos: float = 0.0
var _floor_music_name: String = ""

var in_boss: bool = false
var _boss_override_active: bool = false
var _boss_paused_pos: float = 0.0

var sfx: Dictionary = {
	"big_shot_laugh": preload("res://assets/audio/sfx/items/BigShot_Laugh.mp3"),
	"dash_1": preload("res://assets/audio/sfx/Dash_1.mp3"),
	"parry_1": preload("res://assets/audio/sfx/Parry_1.mp3"),
	"failed_parry_1": preload("res://assets/audio/sfx/FailedParry_1.mp3"),
	"wii_startup":preload("res://assets/audio/sfx/WiiStartupSFX.mp3"),
	"crash_1": preload("res://assets/audio/sfx/Crash_1.mp3"),
	"oars_on_water": preload("res://assets/audio/sfx/OarsOnWater.mp3")
}

var music: Dictionary = {
	"death_menu": preload("res://assets/audio/music/DeathMusic.mp3"),
	"main_menu": preload("res://assets/audio/music/MainMenu.mp3"),
	"tutorial_screen": preload("res://assets/audio/music/ElevatorMusic.mp3"),
	"floor_1": preload("res://assets/audio/music/FloorMusic_1.mp3"),
	"floor_2": preload("res://assets/audio/music/FloorMusic_2.mp3"),
	"floor_3": preload("res://assets/audio/music/FloorMusic_3.mp3"),
	"shop_1": preload("res://assets/audio/music/ShopMusic_1.mp3"),
	"shop_2": preload("res://assets/audio/music/ShopMusic_2.mp3"),
	"shop_3": preload("res://assets/audio/music/barbie.mp3"),
	"boss_1": preload("res://assets/audio/music/barbie.mp3"),
	"victory_screen": preload("res://assets/audio/music/VictoryMusic.mp3"),
}

var floor_music: Array[String] = ["floor_1", "floor_2", "floor_3"]
var shop_music: Array[String] = ["shop_1", "shop_2", "shop_3"]
var boss_music: Array[String] = ["boss_1"]

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	music_player.stream_paused = false
	music_player.autoplay = false
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "SFX"
	sfx_player.stream_paused = false
	sfx_player.autoplay = false
	add_child(sfx_player)

	if not Signals.room_changed.is_connected(_on_room_changed):
		Signals.room_changed.connect(_on_room_changed)
	if not Signals.room_cleared.is_connected(_on_room_cleared):
		Signals.room_cleared.connect(_on_room_cleared)

func _on_room_changed(room_type: String) -> void:
	if room_type == "shop":
		if in_shop:
			return
		in_shop = true
		_enter_shop_music()
		return

	if in_shop:
		in_shop = false
		_exit_shop_music()

	if room_type == "boss":
		if in_boss:
			return
		in_boss = true
		_enter_boss_music()
	else:
		if in_boss:
			in_boss = false
			_exit_boss_music()

func _on_room_cleared() -> void:
	if in_boss:
		in_boss = false
		_exit_boss_music()

func _enter_shop_music() -> void:
	if _boss_override_active and music_player.playing:
		_boss_paused_pos = music_player.get_playback_position()

	if music_player.playing:
		_floor_paused_pos = music_player.get_playback_position()
	else:
		_floor_paused_pos = 0.0

	play_shop_music()
	_shop_override_active = true

func _exit_shop_music() -> void:
	if not _shop_override_active:
		return

	music_player.stop()
	_shop_override_active = false

	if in_boss:
		_resume_boss_music()
		return

	if _floor_music_name != "":
		play_music(_floor_music_name, true, -20.0)
		if _floor_paused_pos > 0.0:
			music_player.play(_floor_paused_pos)

func _enter_boss_music() -> void:
	if in_shop:
		return

	if music_player.playing:
		_floor_paused_pos = music_player.get_playback_position()
	else:
		_floor_paused_pos = 0.0

	play_boss_music()
	_boss_override_active = true

func _resume_boss_music() -> void:
	play_boss_music()
	_boss_override_active = true
	if _boss_paused_pos > 0.0:
		music_player.play(_boss_paused_pos)
		_boss_paused_pos = 0.0

func _exit_boss_music() -> void:
	if not _boss_override_active:
		return
	if in_shop:
		return

	music_player.stop()
	_boss_override_active = false

	# volver a floor
	if _floor_music_name != "":
		play_music(_floor_music_name, true, -20.0)
		if _floor_paused_pos > 0.0:
			music_player.play(_floor_paused_pos)

func play_music(music_name: String, loop := true, volume_db := 0.0) -> void:
	if not music.has(music_name):
		push_warning("Música '" + music_name + "' no encontrada.")
		return
	music_player.stream = music[music_name]
	music_player.stream.loop = loop
	music_player.volume_db = volume_db
	music_player.play()

func play_floor_music() -> void:
	var random_index: int = randi_range(0, floor_music.size() - 1)
	var music_name: String = floor_music[random_index]
	_floor_music_name = music_name
	play_music(music_name, true, -20)

func play_shop_music() -> void:
	var random_index: int = randi_range(0, shop_music.size() - 1)
	var music_name: String = shop_music[random_index]
	play_music(music_name, true, -20)

func play_boss_music() -> void:
	var random_index: int = randi_range(0, boss_music.size() - 1)
	var music_name: String = boss_music[random_index]
	play_music(music_name, true, -20)

func stop_music() -> void:
	music_player.stop()

func play_sfx(sfx_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not sfx.has(sfx_name):
		push_warning("SFX '" + sfx_name + "' no encontrado.")
		return
	sfx_player.stream = sfx[sfx_name]
	sfx_player.volume_db = volume_db
	sfx_player.pitch_scale = pitch
	sfx_player.play()

func set_music_volume(db: float) -> void:
	music_player.volume_db = db

func set_sfx_volume(db: float) -> void:
	sfx_player.volume_db = db

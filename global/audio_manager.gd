extends Node

var music_player: AudioStreamPlayer
var in_shop: bool = false
var _shop_override_active: bool = false
var _floor_paused_pos: float = 0.0
var _floor_music_name: String = ""

var in_boss: bool = false
var _boss_override_active: bool = false
var _boss_paused_pos: float = 0.0

@export var sfx_polyphony: int = 12
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next_index: int = 0

var sfx: Dictionary = {
	"big_shot_laugh": preload("res://assets/audio/sfx/items/BigShot_Laugh.mp3"),
	"dash_1": preload("res://assets/audio/sfx/Dash_1.mp3"),
	"parry_1": preload("res://assets/audio/sfx/Parry_1.mp3"),
	"failed_parry_1": preload("res://assets/audio/sfx/FailedParry_1.mp3"),
	"wii_startup": preload("res://assets/audio/sfx/WiiStartupSFX.mp3"),
	"crash_1": preload("res://assets/audio/sfx/Crash_1.mp3"),
	"oars_on_water": preload("res://assets/audio/sfx/OarsOnWater.mp3"),
	"scythe_1": preload("res://assets/audio/sfx/ScytheSFX.mp3"),
	"coin_collected": preload("res://assets/audio/sfx/CoinCollectedSFX.mp3"),
	"health_collected": preload("res://assets/audio/sfx/EggEatenSFX.mp3"),
	"chest_opened": preload("res://assets/audio/sfx/ChestOpeningSFX.mp3"),
	"drinking": preload("res://assets/audio/sfx/DrinkingSFX.mp3"),
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
	"boss_1": preload("res://assets/audio/music/DarkBoss3-Music.mp3"),
	"boss_2": preload("res://assets/audio/music/SonicBoss-Music.mp3"),
	"victory_screen": preload("res://assets/audio/music/VictoryMusic.mp3"),
}

var floor_music: Array[String] = ["floor_1", "floor_2", "floor_3"]
var shop_music: Array[String] = ["shop_1", "shop_2", "shop_3"]
var boss_music: Array[String] = ["boss_1", "boss_2"]

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	music_player.stream_paused = false
	music_player.autoplay = false
	add_child(music_player)

	_setup_sfx_players()

	if not Signals.room_changed.is_connected(_on_room_changed):
		Signals.room_changed.connect(_on_room_changed)
	if not Signals.room_cleared.is_connected(_on_room_cleared):
		Signals.room_cleared.connect(_on_room_cleared)

func _setup_sfx_players() -> void:
	for i in range(maxi(sfx_polyphony, 1)):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "SFX"
		p.stream_paused = false
		p.autoplay = false
		add_child(p)
		_sfx_players.append(p)

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

	var p := _get_sfx_player()
	if p == null:
		return

	p.stream = sfx[sfx_name]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func _get_sfx_player() -> AudioStreamPlayer:
	if _sfx_players.is_empty():
		return null

	for i in range(_sfx_players.size()):
		var idx := (_sfx_next_index + i) % _sfx_players.size()
		var p := _sfx_players[idx]
		if not p.playing:
			_sfx_next_index = (idx + 1) % _sfx_players.size()
			return p

	var p := _sfx_players[_sfx_next_index]
	_sfx_next_index = (_sfx_next_index + 1) % _sfx_players.size()
	return p

func set_music_volume(db: float) -> void:
	music_player.volume_db = db

func set_sfx_volume(db: float) -> void:
	for p in _sfx_players:
		p.volume_db = db

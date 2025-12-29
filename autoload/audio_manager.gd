extends Node
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var sfx := {
	
}

var music := {
	"death_menu": preload("res://assets/audio/music/DeathMusic.mp3")
}

func _ready():
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

func play_music(name: String, loop := true, volume_db := 0.0):
	if not music.has(name):
		push_warning("Música '" + name + "' no encontrada.")
		return
	music_player.stream = music[name]
	music_player.stream.loop = loop
	music_player.volume_db = volume_db
	music_player.play()

func stop_music():
	music_player.stop()

func play_sfx(name: String, volume_db := 0.0, pitch := 1.0):
	if not sfx.has(name):
		push_warning("SFX '" + name + "' no encontrado.")
		return
	sfx_player.stream = sfx[name]
	sfx_player.volume_db = volume_db
	sfx_player.pitch_scale = pitch
	sfx_player.play()

func set_music_volume(db: float):
	music_player.volume_db = db

func set_sfx_volume(db: float):
	sfx_player.volume_db = db

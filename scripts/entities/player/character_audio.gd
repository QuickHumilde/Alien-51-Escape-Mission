extends Node
class_name CharacterAudio

@onready var sfx_player: AudioStreamPlayer2D

var sounds := {
	"damage": preload("res://assets/audio/sfx/player/uiuiuiADuque.mp3"),
}

func _ready():
	setup_audio()

func setup_audio():
	sfx_player = AudioStreamPlayer2D.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "SFX"
	sfx_player.max_polyphony = 16
	add_child(sfx_player)

func play_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0):
	if not sounds.has(sound_name):
		push_warning("Sonido '" + sound_name + "' no encontrado.")
		return
	
	sfx_player.stream = sounds[sound_name]
	sfx_player.volume_db = volume_db
	sfx_player.pitch_scale = pitch
	sfx_player.play()
	
func play_damage(): play_sound("damage")

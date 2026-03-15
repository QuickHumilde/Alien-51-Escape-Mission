extends Node

var game_time_scale : float = 1.0

const SECRET: Array[String] = ["5","6","4","5","5","3","5","3","4","5","4","C"]
var progress := 0
const MAX_GAP_SECONDS := 99.0
var last_input_time := 0.0

func _ready() -> void:
	Engine.time_scale = game_time_scale
	last_input_time = Time.get_ticks_msec() / 1000.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var now := Time.get_ticks_msec() / 1000.0
		if now - last_input_time > MAX_GAP_SECONDS:
			progress = 0
		last_input_time = now

		var t = event.as_text_keycode()
		if t.length() != 1:
			return

		_process_char(t.to_upper())

func _process_char(ch: String) -> void:
	if ch == SECRET[progress]:
		progress += 1
		if progress >= SECRET.size():
			progress = 0
			_trigger_secret()
	else:
		progress = 1 if ch == SECRET[0] else 0

func _trigger_secret() -> void:
	Signals.vessel_code.emit()

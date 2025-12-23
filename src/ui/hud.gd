extends CanvasLayer
class_name HudPlayer

@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/Label

var player: Character
var stats: CharacterStats

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	stats=player.get_stats()
	
	apply_borders()
	connect_player_signals()
	update_health()

func connect_player_signals():
	if stats.has_signal("health_changed"):
		stats.health_changed.connect(_on_health_changed)

func _on_health_changed(current_health: float, max_health: float, extra_health: float):
	print(current_health, max_health, extra_health)
	update_health()

func update_health():
	
	var current = player.stats.health
	var maximum = player.stats.max_health
	var extra = player.stats.extra_health
	
	health_bar.max_value = maximum
	health_bar.value = current
	
	if extra <= 0.0:
		health_label.text = str(int(current)) + " / " + str(int(maximum))
	else:
		health_label.text = str(int(current)) + "+" + str(int(extra)) +" / " + str(int(maximum))
		
	if current / maximum < 0.3:
		health_bar.modulate = Color(1, 0, 0)
	elif current / maximum < 0.6:
		health_bar.modulate = Color(1, 0.5, 0)
	else:
		health_bar.modulate = Color(0, 1, 0)

func apply_borders():
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.659)
	style_bg.border_width_left = 2
	style_bg.border_width_right = 2
	style_bg.border_width_top = 2
	style_bg.border_width_bottom = 2
	style_bg.corner_radius_top_left = 5
	style_bg.corner_radius_top_right = 5
	style_bg.corner_radius_bottom_left = 5
	style_bg.corner_radius_bottom_right = 5
	health_bar.add_theme_stylebox_override("background", style_bg)

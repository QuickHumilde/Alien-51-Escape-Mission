extends CanvasLayer
class_name HudPlayer

@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/Label
@onready var item_name = $ItemName
@onready var item_desc = $ItemDescription
@onready var item_back = $ItemBackground

@onready var extra_health_bar = $ExtraHealthBar
@onready var extra_health_label = $ExtraHealthBar/Label

var player: Character
var item: Item
var stats: CharacterStats

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	item = get_tree().get_first_node_in_group("item")
	stats=player.get_stats()
	
	$ItemName.add_theme_font_size_override("font_size", 14)
	$ItemDescription.add_theme_font_size_override("font_size", 10)
	
	_hide_item_info()
	apply_borders()
	extra_apply_borders()
	connect_player_signals()
	connect_item_signals()
	update_health()

func connect_player_signals():
	Signals.health_changed.connect(_on_health_changed)

func connect_item_signals():
	Signals.show_item_information.connect(_show_item_info)
	Signals.hide_item_information.connect(_hide_item_info)

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
		extra_health_bar.visible = false
		extra_health_label.visible=false
	else:
		health_label.text = str(int(current)) + " / " + str(int(maximum))
		extra_health_bar.visible = true
		extra_health_label.visible=true
		extra_health_label.text = str(int(extra))
		extra_health_bar.modulate = Color(0.313, 0.522, 1.0, 1.0)
		
	if current / maximum < 0.3:
		health_bar.modulate = Color(0.686, 0.0, 0.0, 1.0)
	elif current / maximum < 0.6:
		health_bar.modulate = Color(1.0, 0.376, 0.0, 1.0)
	else:
		health_bar.modulate = Color(0.0, 0.765, 0.0, 1.0)

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

func extra_apply_borders():
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
	extra_health_bar.add_theme_stylebox_override("background", style_bg)

func _show_item_info(i_name: String, desc: String):
	item_back.visible=true
	item_desc.visible=true
	item_name.visible=true
	
	item_name.text= str(i_name)
	item_name.modulate= Color(0.0, 0.789, 0.0, 1.0)
	
	item_desc.text= str(desc)

func _hide_item_info():
	item_back.visible=false
	item_desc.visible=false
	item_name.visible=false

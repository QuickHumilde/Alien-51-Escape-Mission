extends CanvasLayer
class_name HudPlayer

@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/Label
@onready var health_label2: RichTextLabel = $NewHealthBar/RichTextLabel
@onready var revives_label = $ReviveCount
@onready var item_name = $ItemName
@onready var item_desc = $ItemDescription
@onready var item_back = $ItemBackground
@onready var item_texture = $ItemImage
@onready var money_amount = $MoneyAmount
@onready var items_amount = $ItemAmount
var cache_item_name : String
var cache_item_desc : String

@onready var extra_health_bar = $ExtraHealthBar
@onready var extra_health_label = $ExtraHealthBar/Label

@onready var new_health_bar = $NewHealthBar

var player: Character
var item: Item
var stats: CharacterStats

func _ready():
	LanguageManager.language_changed.connect(update_texts)
	add_to_group("localizable")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	item = get_tree().get_first_node_in_group("item")
	stats = player.get_stats()
	
	_hide_item_info()
	apply_borders()
	extra_apply_borders()
	connect_player_signals()
	connect_item_signals()
	update_health()
	update_inventory()

func update_texts():
	item_name.text= tr(cache_item_name)
	item_name.modulate= Color(0.0, 0.789, 0.0, 1.0)
	
	item_desc.text= tr(cache_item_desc)

func connect_player_signals():
	Signals.health_changed.connect(_on_health_changed)
	Signals.money_changed.connect(_on_money_changed)
	Signals.show_death_menu.connect(_on_death)
	Signals.items_changed.connect(_on_item_changed)
	Signals.player_revive.connect(_on_revive_player)

func connect_item_signals():
	Signals.show_item_information.connect(_show_item_info)
	Signals.hide_item_information.connect(_hide_item_info)

func _on_health_changed(_current_health: float, _max_health: float, _extra_health: float, _revives: float):
	update_health()

func _on_money_changed(_amount: int):
	update_inventory()

func _on_item_changed():
	update_inventory()

func update_health():
	var current = player.stats.health
	var maximum = player.stats.max_health
	var extra = player.stats.extra_health
	var revives = player.stats.get_revives()
	
	health_bar.max_value = maximum
	health_bar.value = current
	
	new_health_bar.max_value = maximum
	new_health_bar.value = current
	#health_label2.clear()
	#health_label2.append_text("[center]%d\n[b]—[/b]\n%d[/center]" % [int(current), int(maximum)])	
	
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
		
	if revives == 0:
		revives_label.visible=false
	else:
		revives_label.visible=true
		revives_label.text= "×" + str(int(revives))
		if extra == 0:
			revives_label.set_position(Vector2(129.0,11.0), false)
		else:
			revives_label.set_position(Vector2(189.0,11.0), false)
		
	if current / maximum < 0.3:
		health_bar.modulate = Color(0.686, 0.0, 0.0, 1.0)
		new_health_bar.tint_progress  = Color(0.686, 0.0, 0.0, 1.0)
		new_health_bar.tint_under  = Color(0.592, 0.0, 0.0, 0.392)
	elif current / maximum < 0.6:
		health_bar.modulate = Color(1.0, 0.376, 0.0, 1.0)
		new_health_bar.tint_progress  = Color(1.0, 0.376, 0.0, 1.0)
		new_health_bar.tint_under  = Color(0.606, 0.214, 0.0, 0.392)
	else:
		health_bar.modulate = Color(0.0, 0.765, 0.0, 1.0)
		new_health_bar.tint_progress  = Color(0.0, 0.765, 0.0, 1.0)
		new_health_bar.tint_under  = Color(0.0, 0.382, 0.0, 0.392)

func update_inventory():
	var money = player.inventory.get_money()
	money_amount.text = str(money)
	
	var items = player.inventory.get_items()
	items_amount.text = str(items)

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

func _show_item_info(i_name: String, desc: String, image: String):
	item_back.visible=false
	item_desc.visible=true
	item_name.visible=true
	
	set_item_icon(image)
	item_texture.visible=true
	item_texture.size = Vector2(8,8)
	cache_item_name=str(i_name)
	cache_item_desc=str(desc)
	
	item_name.text= tr(str(i_name))
	item_name.modulate= Color(0.0, 0.789, 0.0, 1.0)
	
	item_desc.text= tr(str(desc))

func _hide_item_info():
	item_back.visible=false
	item_desc.visible=false
	item_name.visible=false
	item_texture.visible=false

func set_item_icon(image: String):
	item_texture.texture = load(image)

func _on_death():
	self.hide()

func _on_revive_player():
	self.show()

extends CanvasLayer
class_name HudPlayer

# =============================================================================
# REFERENCIAS A NODOS DEL HUD
# =============================================================================

# Barra de salud principal y su etiqueta de texto
@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/Label
# Barra de salud alternativa con RichTextLabel (nueva versión visual)
@onready var health_label2: RichTextLabel = $NewHealthBar/RichTextLabel
# Etiqueta que muestra el número de revives disponibles
@onready var revives_label = $ReviveCount

# Elementos de información de ítem (nombre, descripción, fondo e icono)
@onready var item_name = $ItemName
@onready var item_desc = $ItemDescription
@onready var item_back = $ItemBackground
@onready var item_texture = $ItemImage

# Estadísticas del inventario mostradas en el HUD
@onready var money_amount = $Stats/MoneyAmount
@onready var strenght_amount = $Stats/StrenghtStatLabel
@onready var speed_amount = $Stats/SpeedStatLabel
@onready var lifetime_amount = $Stats/LifetimeStatLabel
@onready var invulnerability_amount = $Stats/InvulnerabilityStatLabel
@onready var items_amount = $ItemAmount

# Caché del nombre y descripción del ítem actual (para relocalizar sin re-señalizar)
var cache_item_name: String
var cache_item_desc: String

# Barra y etiqueta de salud extra (escudo)
@onready var extra_health_bar = $ExtraHealthBar
@onready var extra_health_label = $ExtraHealthBar/Label

# Nueva barra de salud (versión visual alternativa)
@onready var new_health_bar = $NewHealthBar

# Referencias a los nodos de lógica del juego
var player: Character
var item: Item
var stats: CharacterStats


# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready():
	# Se suscribe al sistema de localización para actualizar textos al cambiar idioma
	LanguageManager.language_changed.connect(update_texts)
	add_to_group("localizable")

	# Espera un frame para que el árbol esté completo antes de buscar nodos
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


# =============================================================================
# LOCALIZACIÓN
# =============================================================================

# Actualiza los textos de nombre y descripción del ítem cuando cambia el idioma.
func update_texts():
	item_name.text = tr(cache_item_name)
	item_name.modulate = Color(0.0, 0.789, 0.0, 1.0)
	item_desc.text = tr(cache_item_desc)


# =============================================================================
# CONEXIÓN DE SEÑALES
# =============================================================================

# Conecta las señales globales relacionadas con el estado del jugador.
func connect_player_signals():
	Signals.health_changed.connect(_on_health_changed)
	Signals.money_changed.connect(_on_money_changed)
	Signals.show_death_menu.connect(_on_death)
	Signals.items_changed.connect(_on_item_changed)
	Signals.player_revive.connect(_on_revive_player)
	Signals.update_hud_stats.connect(_on_update_hud_stats)

# Conecta las señales globales para mostrar/ocultar la información de ítem.
func connect_item_signals():
	Signals.show_item_information.connect(_show_item_info)
	Signals.hide_item_information.connect(_hide_item_info)


# =============================================================================
# CALLBACKS DE SEÑALES
# =============================================================================

func _on_health_changed(_current_health: float, _max_health: float, _extra_health: float, _revives: float):
	update_health()

func _on_money_changed(_amount: int):
	update_inventory()

func _on_item_changed():
	update_inventory()

func _on_update_hud_stats():
	update_inventory()


# =============================================================================
# ACTUALIZACIÓN DE SALUD
# =============================================================================

# Actualiza todas las barras de salud, la etiqueta de escudo y el contador de revives.
# Cambia el color de la barra según el porcentaje de salud restante.
func update_health():
	var current = player.stats.health
	var maximum = player.stats.max_health
	var extra = player.stats.extra_health
	var revives = player.stats.get_revives()

	health_bar.max_value = maximum
	health_bar.value = current

	new_health_bar.max_value = maximum
	new_health_bar.value = current

	if extra <= 0.0:
		health_label.text = str(int(current)) + " / " + str(int(maximum))
		extra_health_bar.visible = false
		extra_health_label.visible = false
	else:
		# Muestra la barra de escudo cuando hay extra_health
		health_label.text = str(int(current)) + " / " + str(int(maximum))
		extra_health_bar.visible = true
		extra_health_label.visible = true
		extra_health_label.text = str(int(extra))
		extra_health_bar.modulate = Color(0.313, 0.522, 1.0, 1.0)

	# Muestra el contador de revives y ajusta su posición según si hay escudo o no
	if revives == 0:
		revives_label.visible = false
	else:
		revives_label.visible = true
		revives_label.text = "×" + str(int(revives))
		if extra == 0:
			revives_label.set_position(Vector2(129.0, 11.0), false)
		else:
			revives_label.set_position(Vector2(189.0, 11.0), false)

	# Color de la barra: rojo (<30%), naranja (<60%), verde (>=60%)
	if current / maximum < 0.3:
		health_bar.modulate = Color(0.686, 0.0, 0.0, 1.0)
		new_health_bar.tint_progress = Color(0.686, 0.0, 0.0, 1.0)
		new_health_bar.tint_under = Color(0.592, 0.0, 0.0, 0.392)
	elif current / maximum < 0.6:
		health_bar.modulate = Color(1.0, 0.376, 0.0, 1.0)
		new_health_bar.tint_progress = Color(1.0, 0.376, 0.0, 1.0)
		new_health_bar.tint_under = Color(0.606, 0.214, 0.0, 0.392)
	else:
		health_bar.modulate = Color(0.0, 0.765, 0.0, 1.0)
		new_health_bar.tint_progress = Color(0.0, 0.765, 0.0, 1.0)
		new_health_bar.tint_under = Color(0.0, 0.382, 0.0, 0.392)


# =============================================================================
# ACTUALIZACIÓN DE INVENTARIO Y STATS
# =============================================================================

# Actualiza dinero, número de ítems y todas las etiquetas de estadísticas.
func update_inventory():
	var money = player.inventory.get_money()
	money_amount.text = str(money)

	var items = player.inventory.get_items()
	items_amount.text = str(items)

	strenght_amount.text = str(stats.get_damage())
	speed_amount.text = str(stats.get_speed() / 10.0)
	lifetime_amount.text = str(stats.get_lifetime())
	invulnerability_amount.text = str(stats.get_invulnerability_time())


# =============================================================================
# ESTILOS VISUALES DE BARRAS
# =============================================================================

# Aplica un StyleBoxFlat con esquinas redondeadas y borde a la barra de salud principal.
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

# Aplica el mismo estilo a la barra de salud extra (escudo).
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


# =============================================================================
# INFORMACIÓN DE ÍTEM
# =============================================================================

# Muestra el panel de información del ítem con nombre, descripción e icono traducidos.
# Cachea el nombre y la descripción para poder relocalizar sin volver a emitir la señal.
func _show_item_info(i_name: String, desc: String, image: String):
	item_back.visible = false
	item_desc.visible = true
	item_name.visible = true

	set_item_icon(image)
	item_texture.visible = true
	item_texture.size = Vector2(8, 8)
	cache_item_name = str(i_name)
	cache_item_desc = str(desc)

	item_name.text = tr(str(i_name))
	item_name.modulate = Color(0.0, 0.789, 0.0, 1.0)
	item_desc.text = tr(str(desc))

# Oculta todos los elementos del panel de información del ítem.
func _hide_item_info():
	item_back.visible = false
	item_desc.visible = false
	item_name.visible = false
	item_texture.visible = false

# Carga y asigna la textura del icono del ítem desde su ruta de recurso.
func set_item_icon(image: String):
	item_texture.texture = load(image)


# =============================================================================
# VISIBILIDAD DEL HUD
# =============================================================================

# Oculta el HUD completo al morir.
func _on_death():
	self.hide()

# Muestra el HUD de nuevo al revivir.
func _on_revive_player():
	self.show()

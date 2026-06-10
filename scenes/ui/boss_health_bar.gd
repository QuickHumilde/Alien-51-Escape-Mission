extends CanvasLayer

# =============================================================================
# REFERENCIAS A NODOS
# =============================================================================

@onready var healthbar_container: Control = $HealthBarContainer
@onready var healthbar: ProgressBar = $HealthBarContainer/ProgressBar
@onready var boss_name_label: RichTextLabel = $HealthBarContainer/RichTextLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# =============================================================================
# VARIABLES
# =============================================================================

var current_boss: Enemy = null
var _last_health: float = 0.0

# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	# Conecta a las señales de boss detectado
	Signals.boss_detected.connect(_on_boss_detected)
	Signals.boss_died.connect(_on_boss_died)
	# Conecta a la señal de muerte del jugador
	Signals.show_death_menu.connect(_on_player_died)
	
	# Inicialmente oculta
	healthbar_container.visible = false
	
	# Aplicar estilos
	await get_tree().process_frame
	_apply_boss_healthbar_style()

# =============================================================================
# ACTUALIZACIÓN
# =============================================================================

func _process(_delta: float) -> void:
	if current_boss == null or not is_instance_valid(current_boss):
		_hide_healthbar()
		return
	
	# Actualizar barra de vida
	var health_ratio = current_boss.health / current_boss.max_health
	healthbar.value = health_ratio * 100.0
	
	# Mostrar si la salud cambió
	if abs(current_boss.health - _last_health) > 0.01:
		_last_health = current_boss.health
		if not healthbar_container.visible:
			_show_healthbar()

# =============================================================================
# CALLBACKS
# =============================================================================

func _on_boss_detected(boss: Enemy, boss_name: String) -> void:
	current_boss = boss
	_last_health = boss.health
	boss_name_label.text = boss_name
	_show_healthbar()

func _on_boss_died() -> void:
	_hide_healthbar()
	current_boss = null

# NUEVO: Ocultar barra cuando el jugador muere
func _on_player_died() -> void:
	_hide_healthbar()
	current_boss = null

# =============================================================================
# EFECTOS VISUALES
# =============================================================================

func _show_healthbar() -> void:
	if not healthbar_container.visible:
		healthbar_container.visible = true
		if animation_player.has_animation("fade_in"):
			animation_player.play("fade_in")

func _hide_healthbar() -> void:
	if healthbar_container.visible:
		if animation_player.has_animation("fade_out"):
			await animation_player.animation_finished
		healthbar_container.visible = false


# =============================================================================
# ESTILOS VISUALES (IGUAL AL HUD DEL JUGADOR)
# =============================================================================

# Aplica un StyleBoxFlat con esquinas redondeadas y borde (igual al del jugador)
func _apply_boss_healthbar_style() -> void:
	# Fondo de la barra (gris oscuro)
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.34, 0.045, 0.049, 0.659)
	style_bg.border_width_left = 2
	style_bg.border_width_right = 2
	style_bg.border_width_top = 2
	style_bg.border_width_bottom = 2
	style_bg.border_color = Color(0.708, 0.066, 0.066, 1.0)
	style_bg.corner_radius_top_left = 5
	style_bg.corner_radius_top_right = 5
	style_bg.corner_radius_bottom_left = 5
	style_bg.corner_radius_bottom_right = 5
	healthbar.add_theme_stylebox_override("background", style_bg)
	
	# Progreso de la barra (rojo/carmesí)
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.55, 0.031, 0.095, 0.78)
	style_fill.border_width_left = 2
	style_fill.border_width_right = 2
	style_fill.border_width_top = 2
	style_fill.border_width_bottom = 2
	style_fill.border_color = Color(0.788, 0.063, 0.153, 0.0)
	style_fill.corner_radius_top_left = 3
	style_fill.corner_radius_top_right = 3
	style_fill.corner_radius_bottom_left = 3
	style_fill.corner_radius_bottom_right = 3
	healthbar.add_theme_stylebox_override("fill", style_fill)
	
	# Área vacía (debajo de la barra de progreso) - rojo oscuro
	var style_empty = StyleBoxFlat.new()
	style_empty.bg_color = Color(0.392, 0.032, 0.076, 0.659)
	style_empty.corner_radius_top_left = 3
	style_empty.corner_radius_top_right = 3
	style_empty.corner_radius_bottom_left = 3
	style_empty.corner_radius_bottom_right = 3
	healthbar.add_theme_stylebox_override("fill_under", style_empty)
	
	# Etiqueta del nombre del boss
	boss_name_label.add_theme_color_override("font_color", Color(0.788, 0.064, 0.153, 1.0))
	boss_name_label.add_theme_font_size_override("font_size", 32)

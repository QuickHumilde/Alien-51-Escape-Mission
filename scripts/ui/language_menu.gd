extends Control
signal back_pressed

func _ready():
	update_button_colors()
	add_to_group("localizable")
	update_texts()
	$PanelContainer/VBoxContainer/English.pressed.connect(func(): change_language("en"))
	$PanelContainer/VBoxContainer/Spanish.pressed.connect(func(): change_language("es"))
	$Back.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	back_pressed.emit()
	queue_free()

func change_language(locale: String):
	LanguageManager.set_language(locale)
	update_texts()
	update_button_colors()

func update_texts():
	$Select.text = tr("menu_select_language")
	$Back.text = tr("menu_back")

func update_button_colors():
	var locale = LanguageManager.current_locale

	$PanelContainer/VBoxContainer/English.modulate = Color(1.0, 1.0, 1.0, 1.0)
	$PanelContainer/VBoxContainer/Spanish.modulate = Color(1.0, 1.0, 1.0, 1.0)

	match locale:
		"en":
			$PanelContainer/VBoxContainer/English.modulate = Color(0.2, 0.6, 1.0)
		"es":
			$PanelContainer/VBoxContainer/Spanish.modulate = Color(0.2, 0.6, 1.0)

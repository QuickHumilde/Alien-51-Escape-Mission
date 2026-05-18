extends Node2D

@onready var button_manager: Control = $ButtonManager
@onready var back_menu_button: Button = $ButtonManager/GoBackToMenu
@onready var cursor_label: RichTextLabel = $Pag2/CursorTutorialLabel
@onready var item_label: RichTextLabel = $Pag3/ItemsTutorialLabel
@onready var weapon_label: RichTextLabel = $Pag4/ItemsTutorialLabel
@onready var abilities_label: RichTextLabel = $Pag5/AbilitiesTutorialLabel

@onready var pages: Array[Node] = [$Pag1, $Pag2, $Pag3, $Pag4, $Pag5]
var current_page: int = 1

func _ready() -> void:
	add_to_group("localizable")
	update_texts()

	button_manager.show()
	AudioManager.play_music("tutorial_screen", true, -20.0)

	_connect_page_arrows()
	_show_page(1)

func update_texts() -> void:
	back_menu_button.text = tr("menu_back_to_menu")
	cursor_label.text = tr("cursor_tutorial_label")
	item_label.text = tr("item_tutorial_label")
	weapon_label.text = tr("weapon_change_tutorial_label")
	abilities_label.text = tr("abilities_tutorial_label")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("escape"):
		return
	get_viewport().set_input_as_handled()

func _on_go_back_to_menu_pressed() -> void:
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _connect_page_arrows() -> void:
	for i in range(pages.size()):
		var page := pages[i]
		if page == null:
			continue

		var left := page.get_node_or_null("Left")
		if left != null:
			_connect_arrow(left, Callable(self, "_on_left_pressed").bind(i + 1))

		var right := page.get_node_or_null("Right")
		if right != null:
			_connect_arrow(right, Callable(self, "_on_right_pressed").bind(i + 1))

func _connect_arrow(node: Node, cb: Callable) -> void:
	if node.has_signal("pressed"):
		if not node.is_connected("pressed", cb):
			node.connect("pressed", cb)
		return

	if node.has_signal("input_event"):
		if not node.is_connected("input_event", cb):
			node.connect("input_event", cb)
		return

func _on_left_pressed(page_num: int, _a = null, _b= null, _c = null) -> void:
	_show_page(page_num - 1)

func _on_right_pressed(page_num: int, _a = null, _b = null, _c = null) -> void:
	_show_page(page_num + 1)

func _show_page(page_num: int) -> void:
	current_page = clamp(page_num, 1, pages.size())

	for i in range(pages.size()):
		var p := pages[i]
		if p == null:
			continue
		p.visible = (i == current_page - 1)

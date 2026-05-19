extends Node

signal language_changed(locale: String)
var current_locale: String = "en"

func _ready():
	TranslationServer.set_locale(current_locale)
	language_changed.emit()

func set_language(locale: String):
	current_locale = locale
	TranslationServer.set_locale(locale)
	language_changed.emit()
	for node in get_tree().get_nodes_in_group("localizable"):
		if node.has_method("update_texts"):
			node.update_texts()

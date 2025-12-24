extends Node

signal show_item_information(item_name: String, item_description: String)
signal hide_item_information()

signal health_changed(current: float, maximum: float, extra: float)

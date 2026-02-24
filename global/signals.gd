extends Node

var player_is_dead = false

#region Items
signal show_item_information(item_name: String, item_description: String, item_texture: String)
signal hide_item_information()
#endregion

#region Player
signal health_changed(current: float, maximum: float, extra: float, revives: float)
signal player_death()
signal show_death_menu()
signal player_revive()
#endregion

#Made for remove the warning
func _emit_all():
	show_item_information.emit()
	hide_item_information.emit()
	health_changed.emit()
	player_death.emit()
	show_death_menu.emit()
	player_revive.emit()

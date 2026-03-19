extends Node

var player_is_dead = false

#region Items
signal show_item_information(item_name: String, item_description: String, item_texture: String)
signal hide_item_information()
#endregion

#region Player
signal health_changed(current: float, maximum: float, extra: float, revives: float)
signal player_death()
signal player_take_damage(damage: float)
signal show_death_menu()
signal player_revive()
#endregion

#region Inventory
signal money_changed(money: int)
signal item_picked()
signal items_changed()
#endregion

#region Map
signal room_changed(room_type: String)
signal room_cleared()
signal floor_changed()
#endregion

#region Modifiers
signal shop_price_mult_changed()
#endregion

#region Secrets
signal vessel_code()
#endregion

# Made for removing the warning
func _emit_all():
	show_item_information.emit()
	hide_item_information.emit()
	health_changed.emit()
	player_death.emit()
	show_death_menu.emit()
	player_revive.emit()
	player_take_damage.emit()
	vessel_code.emit()
	money_changed.emit()
	room_changed.emit()
	room_cleared.emit()
	item_picked.emit()
	items_changed.emit()
	floor_changed.emit()
	shop_price_mult_changed.emit()

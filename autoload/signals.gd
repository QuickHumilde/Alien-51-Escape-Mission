extends Node

var player_is_dead = false

#region Items
signal show_item_information(item_name: String, item_description: String)
signal hide_item_information()
#endregion

#region Player
signal health_changed(current: float, maximum: float, extra: float)
signal player_death()
signal show_death_menu()
#endregion

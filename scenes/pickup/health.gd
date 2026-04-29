extends Pickup

@export var health: int = 1
@export var player_collision_layer: int = 3

func _ready() -> void:
	super._ready()
	Signals.health_changed.connect(_on_health_changed)
	change_visibility()

func _on_pick_up(player: Character):
	if picked == false and player.stats.heal(health):
		picked=true
		destroy()
	else:
		change_visibility()

func _on_health_changed(_current: float, _maximum: float, _extra: float, _revives: float):
	change_visibility()

func change_visibility() -> void:
	var player_area: CharacterBody2D = get_tree().get_first_node_in_group("player")
	var can_pick: bool= true

	if player_area != null:
		var player := player_area.get_parent() as Character
		if player != null:
			can_pick = player.stats.current_health < player.stats.max_health

	visible = can_pick
	hitbox.set_collision_mask_value(player_collision_layer, can_pick)

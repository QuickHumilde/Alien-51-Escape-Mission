extends Node2D
class_name ProductSpawner

@onready var price_label: Label = $PriceLabel
@onready var buy_area: Area2D = $BuyArea
@export var use_global_random: bool = true
@export var timer: float = 2.0

var inst: Node = null
var price: int = 10
var can_buy := false

# --- Persistencia ---
var has_spawned: bool = false
var spawned_item_id: int = -1
var was_purchased: bool = false

func _ready() -> void:
	buy_area.area_entered.connect(_on_area_entered)
	Signals.room_changed.connect(_on_room_change)
	Signals.shop_price_mult_changed.connect(_on_shop_price_mult_changed)

	# Si estamos cargando, NO spawnear aquí (lo hará load_save_state)
	if SaveManager != null and SaveManager.is_loading():
		return

	call_deferred("_spawn_item_deferred")

# --- SAVE API ---
func get_spawner_key() -> String:
	return str(get_path())

func get_save_state() -> Dictionary:
	return {
		"has_spawned": has_spawned,
		"spawned_item_id": spawned_item_id,
		"was_purchased": was_purchased,
	}

func load_save_state(state: Dictionary) -> void:
	has_spawned = bool(state.get("has_spawned", false))
	spawned_item_id = int(state.get("spawned_item_id", -1))
	was_purchased = bool(state.get("was_purchased", false))

	# Limpia lo que hubiese (por seguridad)
	for c in get_children():
		if c is Item:
			c.queue_free()

	inst = null
	price_label.show()

	# Si ya se compró, no debe haber item
	if was_purchased:
		price_label.hide()
		return

	# Si había item spawneado, respawnea el mismo
	if has_spawned and spawned_item_id >= 0:
		_spawn_specific_item(spawned_item_id)
	else:
		# si no había info (save viejo), genera uno nuevo
		call_deferred("_spawn_item_deferred")

func _spawn_item_deferred() -> void:
	# Si ya hay item como hijo, no re-spawnees
	for c in get_children():
		if c is Item:
			return

	if ItemManager.item_pool.is_empty():
		return

	var rng := GameManager.rng
	var item_id: int = ItemManager.pick_random_item_id(rng)
	if item_id < 0:
		return

	spawned_item_id = item_id
	has_spawned = true
	_spawn_specific_item(item_id)

	# IMPORTANTE: solo marcar removed cuando lo eliges por primera vez
	ItemManager.mark_removed(item_id)

func _spawn_specific_item(item_id: int) -> void:
	var ps: PackedScene = ItemManager.get_scene(item_id)
	if ps == null:
		return

	inst = ps.instantiate()
	add_child(inst)

	update_prices()

	if inst.has_method("disable_hitbox"):
		inst.disable_hitbox()

	if inst is Node2D:
		(inst as Node2D).global_position = global_position

	can_buy = false
	await get_tree().create_timer(timer).timeout
	can_buy = true

func _on_area_entered(body) -> void:
	if not can_buy:
		return

	if body.is_in_group("player"):
		var player: Character = body.get_parent()
		if player.inventory.spend_money(price):
			can_buy = false
			alien_millonetis()

func _on_room_change(_room_type) -> void:
	can_buy = false
	await get_tree().create_timer(timer).timeout
	can_buy = true

func alien_millonetis() -> void:
	was_purchased = true

	if inst != null and is_instance_valid(inst) and inst.has_method("enable_hitbox"):
		Signals.purchased_shop_item.emit()
		inst.enable_hitbox()

	price_label.hide()

func get_item_price() -> int:
	if inst == null or not is_instance_valid(inst):
		return 0
	return GlobalModifiers.apply_shop_price(inst.get_price())

func update_prices() -> void:
	price = get_item_price()
	price_label.text = str(price) + "$"

func _on_shop_price_mult_changed() -> void:
	update_prices()

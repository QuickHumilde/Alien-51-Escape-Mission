extends Node2D
class_name ProductSpawner

@onready var price_label: Label = $PriceLabel
@onready var buy_area: Area2D = $BuyArea
@export var use_global_random: bool = true
@export var timer= 2.0
var inst = null
var price: int = 10
var can_buy := false

func _ready() -> void:
	call_deferred("_spawn_item_deferred")
	buy_area.area_entered.connect(_on_area_entered)
	Signals.room_changed.connect(_on_room_change)
	Signals.shop_price_mult_changed.connect(_on_shop_price_mult_changed)

func _spawn_item_deferred() -> void:
	for c in get_children():
		if c is Item:
			return

	if ItemManager.item_pool.is_empty():
		return

	var rng := GameManager.rng

	var item_id: int = ItemManager.pick_random_item_id(rng)
	if item_id < 0:
		return

	var ps: PackedScene = ItemManager.get_scene(item_id)
	if ps == null:
		return

	inst = ps.instantiate()
	add_child(inst)

	update_prices()

	inst.disable_hitbox()

	if inst is Node2D:
		inst.global_position = global_position

	ItemManager.mark_removed(item_id)

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

func _on_room_change() -> void:
	can_buy = false
	await get_tree().create_timer(timer).timeout
	can_buy = true

func alien_millonetis():
	inst.enable_hitbox()
	price_label.hide()

func get_item_price():
	return GlobalModifiers.apply_shop_price(inst.get_price())

func update_prices():
	price = get_item_price()
	price_label.text = str(price) + "$"

func _on_shop_price_mult_changed():
	update_prices()

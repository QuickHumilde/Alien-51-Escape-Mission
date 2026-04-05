extends Node
class_name CharacterCombat

var stats: CharacterStats = null
var current_weapon: Node2D = null
@export var current_weapon_index: int = 0
var weapon_holder: Node2D = null

@export var orbit_radius: float = 13
@export var weapon_orbit_radius : float = 0
@export var orbit_smoothness: float = 10.0

#region Weapons Scenes
var arm_scene: PackedScene = preload("res://scenes/weapons/arm_weapon.tscn")
var pistol_scene: PackedScene = preload("res://scenes/weapons/pistol_weapon.tscn")
var nail_scene: PackedScene = preload("res://scenes/weapons/nail_weapon.tscn")
var blue_marker_scene: PackedScene = preload("res://scenes/weapons/blue_marker_weapon.tscn")
var continous_laser_scene : PackedScene = preload("res://scenes/weapons/continous_laser_weapon.tscn")
var exploding_kittens_scene: PackedScene = preload("res://scenes/weapons/exploding_kittens_weapon.tscn")
var shotgun_inter_mark_hat_scene: PackedScene = preload("res://scenes/weapons/shotgun_inter_mark_weapon.tscn")
var black_knife_scene: PackedScene = preload("res://scenes/weapons/black_knife_weapon.tscn")
#endregion

var weapon_scenes : Dictionary = {}
@export var weapon_instances : Dictionary = {} 
@export var weapon_order : Array = [1]

func _ready():
	fill_weapon_scenes()

func fill_weapon_scenes():
	weapon_scenes = {
		1: arm_scene,
		2: pistol_scene,
		3: blue_marker_scene,
		4: nail_scene,
		5: continous_laser_scene,
		6: exploding_kittens_scene,
		7: shotgun_inter_mark_hat_scene,
		8: black_knife_scene,
	}

func init(holder: Node2D, character_stats: CharacterStats):
	weapon_holder = holder
	stats = character_stats

	if weapon_scenes.is_empty():
		_ready()

	if weapon_order.is_empty() and stats == null:
		random_weapon()
	else:
		var initial_id = weapon_order[current_weapon_index]
		equip_weapon(initial_id)
	
func update(delta: float, character):
	if not current_weapon:
		return

	var mouse_pos = character.get_global_mouse_position()
	var angle_to_mouse = (mouse_pos - character.global_position).angle()
	var target_offset = Vector2.RIGHT.rotated(angle_to_mouse) * orbit_radius

	if not current_weapon.is_attacking:
		current_weapon.position = current_weapon.position.lerp(target_offset, delta * orbit_smoothness)
		current_weapon.rotation = lerp_angle(current_weapon.rotation, angle_to_mouse, delta * orbit_smoothness)

	if abs(angle_to_mouse) > PI/2 and not current_weapon.is_attacking:
		current_weapon.scale.y = -1
	else:
		current_weapon.scale.y = 1

	if Input.is_action_pressed("shoot"):
		shoot()
		
	if Input.is_action_just_released("shoot"):
		if current_weapon and current_weapon.has_method("stop_shooting"):
			current_weapon.stop_shooting()

	if Input.is_action_just_pressed("next_weapon"):
		if current_weapon and current_weapon.has_method("stop_shooting"):
			current_weapon.stop_shooting()
		next_weapon()
		
	if Input.is_action_just_pressed("tests"):
		Input.warp_mouse(Vector2(500, 500))

func shoot():
	if current_weapon.has_method("start_shooting"):
		current_weapon.start_shooting(stats.get_damage(), stats.get_lifetime())
	elif current_weapon.has_method("shoot"):
		current_weapon.shoot(stats.get_damage(), stats.get_lifetime())

func equip_weapon(id: int):
	if not weapon_scenes.has(id):
		return

	if current_weapon:
		current_weapon.visible = false
		current_weapon.set_process(false)

	if not weapon_instances.has(id):
		var scene: PackedScene = weapon_scenes[id]
		var instance = scene.instantiate()
		weapon_holder.add_child(instance)
		weapon_instances[id] = instance

	current_weapon = weapon_instances[id]
	current_weapon.visible = true
	current_weapon.set_process(true)

func remove_weapon(id: int):
	var current_id = weapon_order[current_weapon_index]
	if current_id == id:
		weapon_order.erase(id)
		equip_last_weapon()
	else:
		weapon_order.erase(id)
		
func next_weapon():
	current_weapon_index += 1
	if current_weapon_index >= weapon_order.size():
		current_weapon_index = 0

	var next_id = weapon_order[current_weapon_index]
	equip_weapon(next_id)

func add_weapon(id: int):
	if not weapon_scenes.has(id):
		return

	if id not in weapon_order:
		weapon_order.append(id)
	
	equip_last_weapon()

func equip_last_weapon():
	
	var last_id: int=0
	
	for item_id in weapon_order:
		last_id=item_id
		
	equip_weapon(last_id)

func random_weapon():
	var rng := RandomNumberGenerator.new()
	var keys := weapon_scenes.keys()
	var chosen_weapon: int = int(keys[rng.randi_range(0, keys.size() - 1)])
	weapon_order.append(chosen_weapon)
	current_weapon_index = weapon_order.size() - 1
	equip_weapon(chosen_weapon)
	

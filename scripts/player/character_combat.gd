extends Node
class_name CharacterCombat

var stats: CharacterStats = null
var current_weapon: Node2D = null
@export var current_weapon_index: int = 0
var weapon_holder: Node2D = null

@export var orbit_radius: float = 13.5
@export var weapon_orbit_radius : float = 0
@export var orbit_smoothness: float = 10.0

var arm_scene: PackedScene = preload("res://scenes/weapons/arm_weapon.tscn")
var pistol_scene: PackedScene = preload("res://scenes/weapons/pistol_weapon.tscn")
var wizard_hat_scene: PackedScene = preload("res://scenes/weapons/wizard_hat_weapon.tscn")
var nail_scene: PackedScene = preload("res://scenes/weapons/nail_weapon.tscn")

var weapon_scenes := {}
@export var weapon_instances := {} 
@export var weapon_order := [1,3,4]

func _ready():
	weapon_scenes = {
		1: arm_scene,
		2: pistol_scene,
		3: wizard_hat_scene,
		4: nail_scene
	}

func init(holder: Node2D, character_stats: CharacterStats):
	weapon_holder = holder
	stats = character_stats

	if weapon_scenes.is_empty():
		_ready()
		
	if weapon_order.is_empty():
		pass
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


	# Flip cuando mira a la izquierda
	if abs(angle_to_mouse) > PI/2 and not current_weapon.is_attacking:
		current_weapon.scale.y = -1
	else:
		current_weapon.scale.y = 1

	if Input.is_action_just_pressed("shoot"):
		shoot()

	if Input.is_action_just_pressed("next_weapon"):
		next_weapon()

func shoot():
	if current_weapon and current_weapon.has_method("shoot"):
		current_weapon.shoot(stats.get_damage())

func equip_weapon(id: int):
	if not weapon_scenes.has(id):
		push_error("Weapon id '%s' no está en weapon_scenes" % id)
		return

	# Ocultar arma actual
	if current_weapon:
		current_weapon.visible = false
		current_weapon.set_process(false)

	# Instanciar solo si no existe aún
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

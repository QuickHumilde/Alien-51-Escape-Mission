extends Node
class_name CharacterCombat

var stats: CharacterStats = null
var current_weapon: Node2D = null
@export var current_weapon_index: int = 0
var weapons: Array = []
var weapon_holder: Node2D = null
@export var orbit_radius: float = 16.0
@export var orbit_smoothness: float = 10.0

@onready var arm_scene: PackedScene = preload("res://scenes/weapons/arm_weapon.tscn")
@onready var pistol_scene: PackedScene = preload("res://scenes/weapons/provisional_gun.tscn")

func init(holder: Node2D, character_stats: CharacterStats):
	weapon_holder = holder
	stats = character_stats
	weapons = [arm_scene, pistol_scene]
	equip_weapon(arm_scene)

func update(delta: float, character):
	if not current_weapon:
		return

	var mouse_pos = character.get_global_mouse_position()
	var angle_to_mouse = (mouse_pos - character.global_position).angle()
	var target_offset = Vector2.RIGHT.rotated(angle_to_mouse) * orbit_radius

	current_weapon.position = current_weapon.position.lerp(target_offset, delta * orbit_smoothness)
	current_weapon.rotation = lerp_angle(current_weapon.rotation, angle_to_mouse, delta * orbit_smoothness)

	if Input.is_action_just_pressed("shoot"):
		shoot()
		
	if Input.is_action_just_pressed("next_weapon"):
		next_weapon()

func shoot():
	if current_weapon and current_weapon.has_method("shoot"):
		current_weapon.shoot()

func equip_weapon(scene: PackedScene, ):
	if current_weapon:
		current_weapon.queue_free()
	current_weapon = scene.instantiate()
	weapon_holder.add_child(current_weapon)

func next_weapon():
	current_weapon_index += 1
	if current_weapon_index >= weapons.size():
		current_weapon_index = 0
	equip_weapon(weapons[current_weapon_index])

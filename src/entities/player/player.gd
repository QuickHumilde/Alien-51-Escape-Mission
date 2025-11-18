extends CharacterBody2D
class_name Character

#region Variables	
var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
@export var SPEED := 100
var state : String = "idle"
@export var health : int = 5
@export var orbit_radius := 16.0
@export var orbit_smoothness := 10.0 # cuanto más grande, más rápido sigue el ratón
@onready var sprite := $AnimatedSprite2D
@onready var weapon_holder = $WeaponHolder
var current_weapon = null
var current_weapon_index = 0
signal health_changed(new_health)

var weapons=[]

#endregion

#region Weapons Scenes

@onready var arm_scene = preload("res://scenes/weapons/arm_weapon.tscn")
@onready var provisional_pistol_scene = preload("res://scenes/weapons/provisional_gun.tscn")

#endregion

func _ready():
	$Detector.area_entered.connect(_on_hitbox_enter)
	weapons = [arm_scene, provisional_pistol_scene,]
	equip_weapon(arm_scene)
# Se llama cada frame (delta es el tiempo que ha pasado desde el frame anterior)
func _process(delta):
		
	direction.x= Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y= Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	velocity = direction * SPEED
	
	# Actualiza la animacion si el estado o la direccion han cambiado
	if set_state() || set_direction():
		update_animation()
		
		#JAJAS
	if Input.is_key_pressed(KEY_R):
		sprite.rotate(deg_to_rad(180))
		
		#JAJAS
	if Input.is_key_label_pressed(KEY_T):
		SPEED=1000

	# --- ROTACIÓN Y ÓRBITA SUAVES ---
	var mouse_pos = get_global_mouse_position()
	var angle_to_mouse = (mouse_pos - global_position).angle()

	# posición objetivo del arma (alrededor del jugador)
	var target_offset = Vector2.RIGHT.rotated(angle_to_mouse) * orbit_radius

	# interpolar suavemente posición local del arma
	current_weapon.position = current_weapon.position.lerp(target_offset, delta * orbit_smoothness)

	# interpolar suavemente rotación del arma hacia el ratón
	current_weapon.rotation = lerp_angle(current_weapon.rotation, angle_to_mouse, delta * orbit_smoothness)
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
		
	if Input.is_action_just_pressed("next_weapon"):
		next_weapon()

func _physics_process(_delta):
	move_and_slide()

func set_direction() -> bool:
	var new_direction : Vector2 = cardinal_direction
	
	if direction==Vector2.ZERO:
		return false
		
	if direction.y == 0:
		new_direction = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_direction = Vector2.UP if direction.y < 0 else Vector2.DOWN
	
	if new_direction == cardinal_direction:
		return false
	
	cardinal_direction = new_direction
	
	# -1 Si el jugador esta mirando a la izq y 1 si esta mirando a la der
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	
	return true

# Si el estado del jugador no cambia devuelve false, si ha cambiado devuelve true
func set_state() -> bool:
	
	# Detecta si el jugador se esta moviendo y guarda el estado en la variable
	var new_state : String = "idle" if direction == Vector2.ZERO else "walk"
	
	# Si el estado no cambia devuelve false
	if new_state == state:
		return false
	state=new_state
	
	return true

# Actualizo la animacion del jugador
func update_animation():
	sprite.play(state + "_" + anim_direction())
	pass

# Compruebo la direccion cardinal del jugador y devuelvo una cadina con
#la direccion a la que este mirando
func anim_direction() -> String:
	if cardinal_direction==Vector2.DOWN:
		return "down"
	elif cardinal_direction==Vector2.UP:
		return "up"
	else:
		return "side"

#IShoots
func shoot():
	
	current_weapon.shoot()
	
	pass

func take_damage(damage: int):
	sprite.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1,1,1)
	health -= damage
	emit_signal("health_changed", health)
	if health <=0:
		die()
		
func die():
	queue_free()

func _on_hitbox_enter(area):
	if area.is_in_group("damage_1"):
		take_damage(1)
		
func equip_weapon(weapon_scene: PackedScene):
	# borrar el arma actual
	if current_weapon:
		current_weapon.queue_free()

	# instanciar la nueva
	current_weapon = weapon_scene.instantiate()

	# meterla en el WeaponHolder
	weapon_holder.add_child(current_weapon)

func next_weapon():
	# Cambiar al siguiente índice
	current_weapon_index += 1
	if current_weapon_index >= weapons.size():
		current_weapon_index = 0  # volver al principio

	# Equipa la nueva arma
	equip_weapon(weapons[current_weapon_index])

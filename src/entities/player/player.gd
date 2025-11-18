extends CharacterBody2D
class_name Character

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
@export var SPEED := 100
var state : String = "idle"
@export var health : int = 5
@export var orbit_radius := 16.0
@export var orbit_smoothness := 10.0 # cuanto más grande, más rápido sigue el ratón
@onready var sprite := $AnimatedSprite2D
@onready var bullet_scene = preload("res://scenes/weapons/player_bullet.tscn")
@onready var arm := $Arm
signal health_changed(new_health)

func _ready():
	$Detector.area_entered.connect(_on_hitbox_enter)

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
	arm.position = arm.position.lerp(target_offset, delta * orbit_smoothness)

	# interpolar suavemente rotación del arma hacia el ratón
	arm.rotation = lerp_angle(arm.rotation, angle_to_mouse, delta * orbit_smoothness)

	 # Ataque manteniendo pulsado
	var tiempo = arm.get_node("Timer")
	if Input.is_action_pressed("shoot"):
		if tiempo.is_stopped():
			shoot()
			tiempo.start(1)
		
	pass	

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
	
	var bullet = bullet_scene.instantiate()
	
	bullet.position=position
	
	bullet.bullet_direction = (position - get_global_mouse_position()).normalized()
	
	arm.get_node("AnimatedSprite2D").play("attacking")
	
	get_parent().add_child(bullet)

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
		

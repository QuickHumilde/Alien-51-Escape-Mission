extends CharacterBody2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var player: CharacterBody2D = get_tree().current_scene.get_node("Player")
@onready var sprite = $AnimatedSprite2D
@export var speed := 50.0
@export var health := 3.0

func _ready() -> void:
	$Detector.area_entered.connect(_on_hitbox_enter)

func _physics_process(_delta):
	if player == null:
		return

	# Perfil del agente
	agent.target_position = player.global_position

	var next_point = agent.get_next_path_position()
	var direction = (next_point - global_position).normalized()

	velocity = direction * speed
	move_and_slide()

func take_damage(damage : float):
	sprite.modulate = Color(1, 0, 0, 1) 
	health -= damage
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1,1,1)
	if health <=0:
		die()

func die():
	queue_free()

func _on_hitbox_enter(area):
	pass
		

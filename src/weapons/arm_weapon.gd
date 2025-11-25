extends Node2D

@onready var cooldown_timer = $ShootCooldown
@onready var melee_hitbox = $Hitbox
@export var damage: float = 1.0

func _ready():
	$Hitbox.area_entered.connect(_on_hitbox_enter)

func shoot():
	if cooldown_timer.is_stopped() == false:
		return
		
	melee_hitbox.monitoring = true
	self.get_node("AnimatedSprite2D").play("attacking")
	melee_hitbox.get_node("AnimatedSprite2D").play("attack")

	await get_tree().create_timer(0.2).timeout
	melee_hitbox.monitoring = false
	
	cooldown_timer.start()

func _on_hitbox_enter(area):
	if area.is_in_group("enemy"):
		var enemy_node = area.get_parent()
		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)
		
		

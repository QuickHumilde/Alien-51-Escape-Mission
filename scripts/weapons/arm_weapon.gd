extends Weapon

@onready var melee_hitbox = $Hitbox
var knockback: Vector2

func _ready():
	$Hitbox.area_entered.connect(_on_hitbox_enter)
	id=1
	damage=1
	knockback_force=150.0

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
	
		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)

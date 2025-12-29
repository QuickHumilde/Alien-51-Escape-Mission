extends Weapon

@onready var melee_hitbox = $Hitbox
@onready var anim = $AnimationPlayer

var knockback: Vector2

func _ready():
	$Hitbox.area_entered.connect(_on_hitbox_enter)
	id = 1
	damage = 1
	knockback_force = 150.0

func shoot():
	if not $ShootCooldown.is_stopped():
		return

	# Reproducir animación de ataque
	anim.play("attack")

	# Esperar a que termine la animación
	await anim.animation_finished

	$ShootCooldown.start()

func _on_hitbox_enter(area):
	if area.is_in_group("enemy"):
		var enemy_node = area.get_parent()

		if enemy_node.has_method("take_damage"):
			enemy_node.take_damage(damage)

		if enemy_node.has_method("apply_knockback"):
			var knockback_direction = (enemy_node.global_position - global_position).normalized()
			enemy_node.apply_knockback(knockback_direction, knockback_force)

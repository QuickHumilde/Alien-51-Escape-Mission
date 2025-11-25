extends Area2D

var speed=75
var bullet_direction = Vector2.RIGHT
@onready var background_tilemap = get_tree().get_current_scene().get_node("Background")
@onready var foreground_tilemap = get_tree().get_current_scene().get_node("Foreground")

func _ready():
	self.body_entered.connect(_on_hitbox_enter)
	self.area_entered.connect(_on_hitbox_enter)
	
func _process(delta: float):
	global_position -= bullet_direction * speed * delta

func _on_hitbox_enter(other):
	if other.is_in_group("enemy") or other.is_in_group("walls"):
		queue_free()

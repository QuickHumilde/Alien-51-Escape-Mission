extends CanvasLayer

@onready var health_bar = $Control/HealthBar
@onready var player = get_tree().get_current_scene().get_node("Player")

func _ready():
	player.health_changed.connect(_on_health_changed)

func _on_health_changed(value):
	health_bar.value = value

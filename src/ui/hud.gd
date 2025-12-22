extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/Label

var player: Character = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		push_error("El jugador son los padres que hicimos por el camino")
		return

extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D

var textures: Array = [
	preload("res://assets/sprites/Obstacle1.png"),
	preload("res://assets/sprites/Obstacle2.png"),
	preload("res://assets/sprites/Obstacle3.png"),
]

func _ready() -> void:
	set_sprite()

func set_sprite():
	var index := randi_range(0, textures.size() - 1)
	sprite.texture = textures[index]

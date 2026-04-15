extends CPUParticles2D

@onready var point_light: PointLight2D = $PointLight2D
@export var min_scale: float = 1.0
@export var max_scale: float = 1.0
@export var light: bool = true
@export var light_time: float = 0.3
@export var light_energy: float = 3.5
@export var light_scale: Vector2 = Vector2(1.0,1.0)
@export var light_color: Color = Color("#fe4400")

func _ready() -> void:
	self.emitting = false
	self.scale_amount_min = min_scale
	self.scale_amount_max = max_scale
	if light:
		point_light.enabled = false
		point_light.energy = light_energy
		point_light.color = light_color
		point_light.scale = light_scale

func play_one_shot():
	self.emitting = false
	self.emitting = true
	
	if light:
		point_light.enabled = true
		await get_tree().create_timer(light_time).timeout
		point_light.enabled = false

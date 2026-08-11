class_name ReliefLighting
extends Node2D

@export_range(0.0, 2.0, 0.01) var uniform_energy := 0.34
@export_range(0.0, 2.0, 0.01) var pointer_energy := 0.16
@export_range(1.0, 8.0, 0.1) var debug_energy_multiplier := 3.5

@onready var uniform_light: DirectionalLight2D = %UniformReliefLight
@onready var pointer_light: PointLight2D = %PointerReliefLight

var enabled := true
var debug_boosted := false


func _ready() -> void:
	_apply_state()


func set_enabled(value: bool) -> void:
	enabled = value
	_apply_state()


func follow_pointer(pointer_position: Vector2, viewport_size: Vector2) -> void:
	pointer_light.position = pointer_position
	var center := viewport_size * 0.5
	var direction := pointer_position - center
	if direction.length_squared() > 1.0:
		# The uniform light keeps the scene even while its highlights subtly follow
		# the pointer direction across tile and icon normal maps.
		uniform_light.rotation = direction.angle() + PI * 0.5


func toggle_debug_boost() -> bool:
	debug_boosted = not debug_boosted
	_apply_state()
	return debug_boosted


func _apply_state() -> void:
	if not is_node_ready():
		return
	uniform_light.visible = enabled
	pointer_light.visible = enabled
	var multiplier := debug_energy_multiplier if debug_boosted else 1.0
	uniform_light.energy = uniform_energy * multiplier
	pointer_light.energy = pointer_energy * multiplier

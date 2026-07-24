class_name FlashlightOverlay
extends ColorRect

@export var flashlight_radius := 54.0
@export var flashlight_softness := 14.0
@export var darkness_alpha := 0.94

var target_position := Vector2(128.0, 160.0)
var light_position := Vector2(128.0, 160.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_shader()


func _process(delta: float) -> void:
	if not visible:
		return
	target_position = get_viewport().get_mouse_position()
	light_position = light_position.lerp(target_position, minf(delta * 14.0, 1.0)).round()
	_update_shader()


func follow_touch(position: Vector2) -> void:
	target_position = position


func _update_shader() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("light_position", light_position)
	shader_material.set_shader_parameter("viewport_size", size)
	shader_material.set_shader_parameter("radius", flashlight_radius)
	shader_material.set_shader_parameter("softness", flashlight_softness)
	shader_material.set_shader_parameter("darkness_alpha", darkness_alpha)

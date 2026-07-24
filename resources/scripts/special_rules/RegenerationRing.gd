class_name RegenerationRing
extends TextureRect

var ratio := 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_update_shader()


func _ready() -> void:
	custom_minimum_size = Vector2(9, 9)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_shader()


func _update_shader() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	var ring_color := Color("#4D82C2")
	if ratio < 0.4:
		ring_color = Color("#E06455").lerp(
			Color("#D0A13A"),
			clampf((ratio - 0.2) / 0.2, 0.0, 1.0)
		)
	else:
		ring_color = Color("#D0A13A").lerp(
			Color("#4D82C2"),
			clampf((ratio - 0.4) / 0.25, 0.0, 1.0)
		)
	shader_material.set_shader_parameter("progress", ratio)
	shader_material.set_shader_parameter("progress_color", ring_color)

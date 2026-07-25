@tool
class_name VolumeSlider
extends HSlider

@onready var bar: TextureRect = get_node("Bar")


func _ready() -> void:
	value_changed.connect(_refresh)
	_refresh()


func _refresh(_value := 0.0) -> void:
	if bar == null or bar.material == null:
		return
	var ratio := inverse_lerp(min_value, max_value, value)
	(bar.material as ShaderMaterial).set_shader_parameter("progress", ratio)

@tool
class_name VolumeSlider
extends HSlider

@onready var bar: TextureRect = get_node("Bar")

var _touch_index := -1


func _ready() -> void:
	value_changed.connect(_refresh)
	_refresh()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_index >= 0:
				return
			_touch_index = touch.index
			_set_value_from_touch(touch.position)
			accept_event()
		elif touch.index == _touch_index:
			_set_value_from_touch(touch.position)
			_touch_index = -1
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch_index:
			return
		_set_value_from_touch(drag.position)
		accept_event()


func _set_value_from_touch(touch_position: Vector2) -> void:
	if size.x <= 0.0:
		return
	var ratio := clampf(touch_position.x / size.x, 0.0, 1.0)
	value = lerpf(min_value, max_value, ratio)


func _refresh(_value := 0.0) -> void:
	if bar == null or bar.material == null:
		return
	var ratio := inverse_lerp(min_value, max_value, value)
	(bar.material as ShaderMaterial).set_shader_parameter("progress", ratio)

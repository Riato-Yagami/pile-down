@tool
class_name VolumeSlider
extends HSlider

const HoverInteractionScript := preload(
	"res://resources/scripts/ui/HoverInteraction.gd"
)

@onready var bar: Control = get_node("Bar")

var _touch_index := -1
var _hover_interaction = HoverInteractionScript.new()


func _ready() -> void:
	_hover_interaction.setup(
		self,
		self,
		&"_show_highlight",
		&"_hide_highlight"
	)
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


func _show_highlight() -> void:
	_set_highlighted(true)


func _hide_highlight() -> void:
	_set_highlighted(false)


func _set_highlighted(highlighted: bool) -> void:
	if bar == null or not bar.material is ShaderMaterial:
		return
	(bar.material as ShaderMaterial).set_shader_parameter(
		"highlighted",
		1.0 if highlighted else 0.0
	)

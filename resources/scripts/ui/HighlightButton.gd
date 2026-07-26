class_name HighlightButton
extends Button

@export var highlight_material: ShaderMaterial

var _touch_index := -1


func _ready() -> void:
	material = null
	mouse_entered.connect(_show_highlight)
	mouse_exited.connect(_hide_highlight)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if disabled or _touch_index >= 0:
				return
			_touch_index = touch.index
			_show_highlight()
			accept_event()
		elif touch.index == _touch_index:
			_touch_index = -1
			_hide_highlight()
			if Rect2(Vector2.ZERO, size).has_point(touch.position):
				pressed.emit()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch_index:
			return
		if Rect2(Vector2.ZERO, size).has_point(drag.position):
			_show_highlight()
		else:
			_hide_highlight()
		accept_event()


func _show_highlight() -> void:
	material = highlight_material


func _hide_highlight() -> void:
	material = null

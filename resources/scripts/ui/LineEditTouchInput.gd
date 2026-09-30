extends Node

## Forward completed taps to native LineEdit handling when mouse emulation is off.
var _finger := -1
var _origin := Vector2.ZERO
var _dragged := false


static func install(input: LineEdit) -> void:
	var bridge := new()
	bridge.name = "TouchInput"
	input.add_child(bridge)
	input.gui_input.connect(bridge._on_gui_input)


func _notification(what: int) -> void:
	if what == Control.NOTIFICATION_SCROLL_BEGIN:
		_finger = -1


func _on_gui_input(event: InputEvent) -> void:
	if Input.is_emulating_mouse_from_touch():
		return
	var input := get_parent() as LineEdit
	if not input.editable:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _finger >= 0:
				return
			_finger = event.index
			_origin = event.position
			_dragged = false
		elif event.index == _finger:
			_finger = -1
			if not event.canceled and not _dragged and Rect2(Vector2.ZERO, input.size).has_point(event.position):
				_click.call_deferred(event.position)
	elif event is InputEventScreenDrag and event.index == _finger:
		_dragged = _dragged or event.position.distance_to(_origin) > 6.0


func _click(local_point: Vector2) -> void:
	var input := get_parent() as LineEdit
	if not input.is_visible_in_tree() or not input.editable:
		return
	var point := input.get_global_transform_with_canvas() * local_point
	# Native click handling positions the caret and opens the platform keyboard,
	# including a second tap after Android has dismissed the keyboard.
	var motion := InputEventMouseMotion.new()
	motion.position = point
	input.get_viewport().push_input(motion, true)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		input.get_viewport().push_input(click, true)

extends Node

## Godot 4.7 PopupMenu handles mouse input, unlike the surrounding touch buttons.
var _finger := -1
var _origin := Vector2.ZERO
var _dragged := false


static func install(popup: Popup) -> void:
	if popup.has_node("TouchInput"):
		return
	var bridge := new()
	bridge.name = "TouchInput"
	popup.add_child(bridge)
	if popup is PopupPanel:
		popup.add_child(preload("res://resources/scripts/ui/MenuTouchScroll.gd").new())


func _input(event: InputEvent) -> void:
	var popup := get_parent() as PopupMenu
	if popup == null or not popup.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _finger >= 0:
				return
			_finger = event.index
			_origin = event.position
			_dragged = false
		elif event.index != _finger:
			return
		popup.set_input_as_handled()
		if not event.pressed:
			_finger = -1
			if event.canceled or _dragged:
				return
			_click.call_deferred(event.position)
	elif event is InputEventScreenDrag and event.index == _finger:
		popup.set_input_as_handled()
		if event.position.distance_to(_origin) > 6.0:
			_dragged = true
		if _dragged:
			for scroll in _popup_scrolls(popup):
				scroll.scroll_vertical -= roundi(event.relative.y)


func _ready() -> void:
	var popup := get_parent() as Popup
	popup.popup_hide.connect(func() -> void: _finger = -1)
	# Embedded windows receive inside taps themselves. Outside taps reach their
	# containing Window and must dismiss the popup without activating the menu.
	var parent_window := popup.get_parent().get_window()
	parent_window.window_input.connect(_outside_input)


func _outside_input(event: InputEvent) -> void:
	var popup := get_parent() as Popup
	if not popup.visible or not popup.is_embedded():
		return
	if event is InputEventScreenTouch and event.pressed:
		var parent_viewport := popup.get_parent().get_viewport()
		var point: Vector2 = parent_viewport.get_final_transform().affine_inverse() * event.position
		if not Rect2(Vector2(popup.position), Vector2(popup.size)).has_point(point):
			popup.hide()
			popup.get_parent().get_viewport().set_input_as_handled()


func _click(point: Vector2) -> void:
	var popup := get_parent() as PopupMenu
	if not popup.visible:
		return
	# A complete click on release avoids selecting a row during a swipe.
	var motion := InputEventMouseMotion.new()
	motion.position = point
	_send_mouse(popup, motion)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		_send_mouse(popup, click)


func _send_mouse(popup: PopupMenu, event: InputEventMouse) -> void:
	if popup.is_embedded():
		event.position = Vector2(popup.position) + event.position * popup.content_scale_factor
		popup.get_parent().get_viewport().push_input(event, true)
	else:
		event.window_id = popup.get_window_id()
		event.position *= popup.content_scale_factor
		Input.parse_input_event(event)


func _popup_scrolls(node: Node) -> Array[ScrollContainer]:
	var result: Array[ScrollContainer] = []
	for child in node.get_children(true):
		if child is ScrollContainer:
			result.append(child)
		else:
			result.append_array(_popup_scrolls(child))
	return result


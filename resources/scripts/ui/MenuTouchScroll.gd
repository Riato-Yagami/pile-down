extends Node

## Capture swipes before child buttons consume GUI events, preserving ordinary taps.
var _scroll: ScrollContainer
var _finger := -1
var _origin := Vector2.ZERO
var _initial := Vector2.ZERO
var _swiping := false
var _canceling := false


func _input(event: InputEvent) -> void:
	if _canceling:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			# Opening a modal on press can route the release to another viewport.
			if _finger >= 0 and _finger != event.index:
				return
			_finger = -1
			_scroll = _scroll_at(get_parent(), event.position)
			if _scroll == null:
				return
			_finger = event.index
			_origin = _scroll.get_global_transform_with_canvas().affine_inverse() * event.position
			_initial = Vector2(_scroll.scroll_horizontal, _scroll.scroll_vertical)
			_swiping = false
		elif event.index == _finger:
			if _swiping:
				if is_instance_valid(_scroll):
					_scroll.propagate_notification(Control.NOTIFICATION_SCROLL_END)
				get_viewport().set_input_as_handled()
			_finger = -1
			_scroll = null
	elif event is InputEventScreenDrag and event.index == _finger:
		if not is_instance_valid(_scroll) or not _scroll.is_visible_in_tree():
			_finger = -1
			return
		var local: Vector2 = _scroll.get_global_transform_with_canvas().affine_inverse() * event.position
		var distance := local - _origin
		if not _swiping and distance.length() < 6.0:
			return
		if not _swiping:
			_swiping = true
			_scroll.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
			var cancel := InputEventScreenTouch.new()
			cancel.index = _finger
			cancel.position = event.position
			cancel.canceled = true
			_canceling = true
			get_viewport().push_input(cancel, true)
			_canceling = false
		if _scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			_scroll.scroll_horizontal = roundi(_initial.x - distance.x)
		if _scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			_scroll.scroll_vertical = roundi(_initial.y - distance.y)
		get_viewport().set_input_as_handled()


func _scroll_at(node: Node, point: Vector2) -> ScrollContainer:
	if node is Window and node != get_parent():
		return null
	if node is Control:
		if not node.is_visible_in_tree():
			return null
		if node.clip_contents and not node.get_global_rect().abs().has_point(point):
			return null
	var children := node.get_children()
	children.reverse()
	for child in children:
		var found := _scroll_at(child, point)
		if found != null:
			return found
	if node is ScrollContainer and node.get_global_rect().abs().has_point(point):
		# Keep direct scrollbar dragging available.
		for bar in [node.get_v_scroll_bar(), node.get_h_scroll_bar()]:
			if bar.is_visible_in_tree() and bar.get_global_rect().has_point(point):
				return null
		if node.get_v_scroll_bar().max_value > node.get_v_scroll_bar().page or node.get_h_scroll_bar().max_value > node.get_h_scroll_bar().page:
			return node
	return null

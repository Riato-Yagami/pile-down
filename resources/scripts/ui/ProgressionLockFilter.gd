@tool
class_name ProgressionLockFilter
extends Control

signal mode_changed(mode: int)

const BOTH := 0
const UNLOCKED := 1
const LOCKED := 2
const MODE_ORDER := [LOCKED, BOTH, UNLOCKED]

@export_enum("Both", "Unlocked", "Locked") var mode := BOTH:
	set(value):
		mode = clampi(value, BOTH, LOCKED)
		_refresh()
@export_range(0.0, 64.0, 0.5, "suffix:px") var selector_right_x := 30.0:
	set(value):
		selector_right_x = maxf(value, 0.0)
		_refresh()

@onready var bar: TextureRect = %LockModeBar
@onready var selector: TextureRect = %LockModeSelector

var _dragging := false
var _touch_index := -1


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	selector.mouse_entered.connect(_set_selector_highlight.bind(true))
	selector.mouse_exited.connect(_set_selector_highlight.bind(false))
	selector.gui_input.connect(_handle_pointer_input.bind(true))
	_refresh()


func set_mode(value: int, emit_change := false) -> void:
	var next_mode := clampi(value, BOTH, LOCKED)
	if mode == next_mode:
		_refresh()
		return
	mode = next_mode
	if emit_change:
		mode_changed.emit(mode)


func _gui_input(event: InputEvent) -> void:
	_handle_pointer_input(event)
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		var index := MODE_ORDER.find(mode)
		if key.keycode == KEY_LEFT:
			set_mode(MODE_ORDER[maxi(index - 1, 0)], true)
			accept_event()
		elif key.keycode == KEY_RIGHT:
			set_mode(MODE_ORDER[mini(index + 1, MODE_ORDER.size() - 1)], true)
			accept_event()


func _handle_pointer_input(event: InputEvent, from_selector := false) -> void:
	var pointer_offset := selector.position if from_selector else Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		_dragging = mouse_button.pressed
		_set_mode_from_position(mouse_button.position + pointer_offset)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_set_mode_from_position(
			(event as InputEventMouseMotion).position + pointer_offset
		)
		accept_event()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index < 0:
			_touch_index = touch.index
			_set_mode_from_position(touch.position + pointer_offset)
			accept_event()
		elif not touch.pressed and touch.index == _touch_index:
			_set_mode_from_position(touch.position + pointer_offset)
			_touch_index = -1
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_set_mode_from_position(drag.position + pointer_offset)
			accept_event()


func _set_mode_from_position(local_position: Vector2) -> void:
	var third := size.x / 3.0
	if local_position.x < third:
		set_mode(LOCKED, true)
	elif local_position.x < third * 2.0:
		set_mode(BOTH, true)
	else:
		set_mode(UNLOCKED, true)


func _refresh() -> void:
	if not is_node_ready():
		return
	var maximum_x := maxf(size.x - selector.size.x, 0.0)
	var center_x := maximum_x * 0.5
	var right_x := clampf(selector_right_x, center_x, maximum_x)
	# The left limit mirrors the editor-defined right limit around the center.
	var left_x := maximum_x - right_x
	var selector_x := left_x
	match mode:
		BOTH:
			selector_x = center_x
		UNLOCKED:
			selector_x = right_x
	selector.position.x = selector_x
	if bar.material is ShaderMaterial:
		(bar.material as ShaderMaterial).set_shader_parameter("selected_mode", mode)


func _set_selector_highlight(highlighted: bool) -> void:
	if selector.material is ShaderMaterial:
		(selector.material as ShaderMaterial).set_shader_parameter(
			"highlighted", 1.0 if highlighted else 0.0
		)

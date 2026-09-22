@tool
class_name ProgressionLockFilter
extends Control

signal mode_changed(mode: int)

const BOTH := 0
const UNLOCKED := 1
const LOCKED := 2
const MODE_ORDER := [BOTH, LOCKED, UNLOCKED]
const HANDLE_BASE_POSITION := Vector2(-2.0, -10.0)

@export_enum("Both", "Unlocked", "Locked") var mode := BOTH:
	set(value):
		var previous_mode := mode
		mode = clampi(value, BOTH, LOCKED)
		_refresh(true, previous_mode)
@export_category("Editor Preview")
@export_enum("Both", "Unlocked", "Locked") var editor_preview_mode := BOTH:
	set(value):
		editor_preview_mode = clampi(value, BOTH, LOCKED)
		if Engine.is_editor_hint():
			mode = editor_preview_mode
@export_category("Layout")
@export var text_offset := Vector2(7.0, 0.0):
	set(value):
		text_offset = value
		_apply_text_offset()
@export_category("Animation")
@export var inactive_color := Color(0.42, 0.42, 0.42, 1.0):
	set(value):
		inactive_color = value
		_refresh()
@export_range(1.0, 2.0, 0.05) var hover_brightness := 1.25:
	set(value):
		hover_brightness = maxf(value, 1.0)
		_refresh()
@export_range(0.05, 0.5, 0.01) var animation_duration := 0.18
@export var locked_handle_offset := Vector2(0.0, 2.0)
@export var unlocked_handle_offset := Vector2.ZERO
@export var unlocked_handle_scale := Vector2(-1.0, 1.0)

@onready var lock_main: TextureRect = %LockMain
@onready var lock_handle: TextureRect = %LockHandle
@onready var handle_flip_anchor: Node2D = %HandleFlipAnchor
@onready var hover_region: Control = %HoverRegion
@onready var icon_offset: Node2D = %IconOffset

var _hovered := false
var _pose_tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hover_region.mouse_entered.connect(_set_icon_highlight.bind(true))
	hover_region.mouse_exited.connect(_set_icon_highlight.bind(false))
	hover_region.gui_input.connect(_on_hover_region_gui_input)
	_apply_text_offset()
	_apply_native_texture_sizes()
	if Engine.is_editor_hint():
		mode = editor_preview_mode
	_refresh(false)


func _on_hover_region_gui_input(event: InputEvent) -> void:
	_gui_input(event)


func _apply_text_offset() -> void:
	if not is_node_ready():
		return
	# Tool setters can run during a packed-scene hot reload after the root becomes
	# ready but before its @onready child references have been restored.
	if not is_instance_valid(icon_offset):
		icon_offset = get_node_or_null("IconOffset") as Node2D
	if not is_instance_valid(icon_offset):
		return
	icon_offset.position = text_offset
	custom_minimum_size = Vector2(
		14.0 + maxf(text_offset.x, 0.0),
		maxf(24.0, 28.0 + text_offset.y)
	)


func _apply_native_texture_sizes() -> void:
	for texture_rect in [lock_main, lock_handle]:
		if texture_rect.texture == null:
			continue
		texture_rect.size = texture_rect.texture.get_size()


func set_mode(value: int, emit_change := false) -> void:
	var next_mode := clampi(value, BOTH, LOCKED)
	if mode == next_mode:
		_refresh()
		return
	mode = next_mode
	if emit_change:
		mode_changed.emit(mode)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_cycle_mode()
			accept_event()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_cycle_mode()
			accept_event()
	elif event is InputEventKey:
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
		elif key.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_cycle_mode()
			accept_event()


func _cycle_mode() -> void:
	var index := MODE_ORDER.find(mode)
	set_mode(MODE_ORDER[(index + 1) % MODE_ORDER.size()], true)


func _refresh(animate := true, previous_mode := -1) -> void:
	if not is_node_ready():
		return
	if not (
		is_instance_valid(lock_main)
		and is_instance_valid(lock_handle)
		and is_instance_valid(handle_flip_anchor)
	):
		return
	var icon_color := Color.WHITE
	if _hovered:
		icon_color = _brightened(icon_color)
	lock_main.modulate = icon_color
	lock_handle.modulate = icon_color
	var pose_offset := Vector2.ZERO
	if mode == LOCKED:
		pose_offset = locked_handle_offset
	elif mode == UNLOCKED:
		pose_offset = unlocked_handle_offset
	var target_position := HANDLE_BASE_POSITION + pose_offset
	var target_scale := unlocked_handle_scale if mode == UNLOCKED else Vector2.ONE
	if _pose_tween and _pose_tween.is_valid():
		_pose_tween.kill()
	if animate and animation_duration > 0.0:
		if previous_mode == LOCKED and mode == UNLOCKED:
			_animate_pose_through_both(target_position, target_scale)
		else:
			_animate_pose(target_position, target_scale, animation_duration)
	else:
		lock_handle.position = target_position
		handle_flip_anchor.scale = target_scale
	tooltip_text = ""


func _animate_pose(
	target_position: Vector2,
	target_scale: Vector2,
	duration: float
) -> void:
	_pose_tween = create_tween().set_parallel(true)
	_pose_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pose_tween.tween_property(lock_handle, "position", target_position, duration)
	_pose_tween.tween_property(handle_flip_anchor, "scale", target_scale, duration)


func _animate_pose_through_both(
	target_position: Vector2,
	target_scale: Vector2
) -> void:
	var midpoint_duration := animation_duration * 0.5
	_pose_tween = create_tween()
	_pose_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pose_tween.tween_property(
		lock_handle, "position", HANDLE_BASE_POSITION, midpoint_duration
	)
	_pose_tween.parallel().tween_property(
		handle_flip_anchor, "scale", Vector2.ONE, midpoint_duration
	)
	_pose_tween.chain().tween_property(
		lock_handle, "position", target_position, midpoint_duration
	)
	_pose_tween.parallel().tween_property(
		handle_flip_anchor, "scale", target_scale, midpoint_duration
	)


func _brightened(color: Color) -> Color:
	return Color(
		color.r * hover_brightness,
		color.g * hover_brightness,
		color.b * hover_brightness,
		color.a
	)


func _set_icon_highlight(highlighted: bool) -> void:
	_hovered = highlighted
	_refresh()


# Kept as a compatibility entry point for editor previews and older tests.
func _set_selector_highlight(highlighted: bool) -> void:
	_set_icon_highlight(highlighted)

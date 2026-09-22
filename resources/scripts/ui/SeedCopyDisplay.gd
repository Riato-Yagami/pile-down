class_name SeedCopyDisplay
extends HBoxContainer

signal seed_copied

const BASE_BLUE := Color("4d82c2")
const HIGHLIGHT_BLUE := Color("6da7e5")

@export_range(1, 80, 1) var collapsed_character_count := 5:
	set(value):
		collapsed_character_count = maxi(value, 1)
		if is_node_ready():
			_refresh_visible_seed(false)
@export_range(0.0, 1.0, 0.01, "suffix:s") var resize_animation_duration := 0.18
@export var copy_feedback_text := "COPIED"
@export_range(0.05, 1.0, 0.01, "suffix:s") var copy_feedback_duration := 0.42
@export var position_offset := Vector2.ZERO:
	set(value):
		position_offset = value
		if is_node_ready():
			_apply_editor_layout()
@export var side_padding := Vector2.ZERO:
	set(value):
		side_padding = value.max(Vector2.ZERO)
		if is_node_ready():
			_apply_editor_layout()
@export_range(0.0, 1000.0, 1.0, "suffix:px") var expanded_label_width := 0.0:
	set(value):
		expanded_label_width = maxf(value, 0.0)
		if is_node_ready():
			_refresh_visible_seed(false)

@onready var left_padding: Control = %LeftPadding
@onready var seed_icon: TextureRect = %SeedIcon
@onready var value_label: Label = %ValueLabel
@onready var copy_button: TextureButton = %CopyButton
@onready var right_padding: Control = %RightPadding

var seed_text := ""
var _highlighted := false
var _resize_tween: Tween
var _copy_feedback_tween: Tween
var _copy_feedback_active := false
var _last_copy_feedback_msec := -1000


func _ready() -> void:
	mouse_entered.connect(_set_highlight.bind(true))
	mouse_exited.connect(_refresh_pointer_highlight.call_deferred)
	copy_button.mouse_entered.connect(_set_highlight.bind(true))
	copy_button.mouse_exited.connect(_refresh_pointer_highlight.call_deferred)
	copy_button.focus_entered.connect(_set_highlight.bind(true))
	copy_button.focus_exited.connect(_refresh_pointer_highlight.call_deferred)
	copy_button.pressed.connect(copy_seed)
	gui_input.connect(_on_gui_input)
	# The label owns only its text width so Copy follows it instead of being
	# pushed to the far edge by the surrounding panel.
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	value_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_apply_editor_layout()
	_set_highlight(false)


func set_seed(value: String) -> void:
	seed_text = value
	tooltip_text = ""
	_refresh_visible_seed()


func set_copy_enabled(enabled: bool) -> void:
	copy_button.disabled = not enabled
	copy_button.visible = enabled
	mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	)


func copy_seed() -> void:
	if seed_text.is_empty() or not DisplayServer.has_feature(
		DisplayServer.FEATURE_CLIPBOARD
	):
		return
	DisplayServer.clipboard_set(seed_text)
	var now := Time.get_ticks_msec()
	if now - _last_copy_feedback_msec < 80:
		return
	_last_copy_feedback_msec = now
	_play_copy_feedback()
	seed_copied.emit()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and not mouse_event.pressed
		):
			copy_seed()
	elif event is InputEventScreenTouch and not event.pressed:
		copy_seed()


func _refresh_pointer_highlight() -> void:
	var viewport := get_viewport()
	_set_highlight(
		viewport != null
		and get_global_rect().has_point(viewport.get_mouse_position())
		or copy_button.has_focus()
	)


func _set_highlight(highlighted: bool) -> void:
	_highlighted = highlighted
	var color := HIGHLIGHT_BLUE if highlighted else BASE_BLUE
	var icon_tint := Color(1.35, 1.35, 1.35, 1.0) if highlighted else Color.WHITE
	seed_icon.self_modulate = icon_tint
	if not _copy_feedback_active:
		value_label.add_theme_color_override("font_color", color)
	copy_button.self_modulate = icon_tint
	_refresh_visible_seed()


func _apply_editor_layout() -> void:
	position = position_offset
	left_padding.custom_minimum_size.x = side_padding.x
	right_padding.custom_minimum_size.x = side_padding.y


func _play_copy_feedback() -> void:
	if not is_instance_valid(value_label):
		return
	if is_instance_valid(_resize_tween):
		_resize_tween.kill()
	if is_instance_valid(_copy_feedback_tween):
		_copy_feedback_tween.kill()
	_copy_feedback_active = true
	value_label.text = copy_feedback_text
	value_label.modulate = Color(1.35, 1.35, 1.35, 1.0)
	value_label.add_theme_color_override("font_color", HIGHLIGHT_BLUE)
	_apply_value_label_width(copy_feedback_text, false)
	value_label.pivot_offset = value_label.size * 0.5
	value_label.scale = Vector2(1.12, 1.12)
	_copy_feedback_tween = create_tween()
	_copy_feedback_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_copy_feedback_tween.tween_property(value_label, "scale", Vector2.ONE, 0.12)
	_copy_feedback_tween.parallel().tween_property(
		value_label, "modulate", Color.WHITE, 0.18
	)
	_copy_feedback_tween.tween_interval(maxf(copy_feedback_duration - 0.18, 0.02))
	_copy_feedback_tween.tween_callback(_finish_copy_feedback)


func _finish_copy_feedback() -> void:
	_copy_feedback_active = false
	value_label.scale = Vector2.ONE
	value_label.modulate = Color.WHITE
	value_label.add_theme_color_override(
		"font_color", HIGHLIGHT_BLUE if _highlighted else BASE_BLUE
	)
	_refresh_visible_seed()


func _refresh_visible_seed(animate := true) -> void:
	if not is_instance_valid(value_label):
		return
	if _copy_feedback_active:
		return
	var visible_text := seed_text if _highlighted else _collapsed_seed_text()
	value_label.text = visible_text
	_apply_value_label_width(visible_text, animate)


func _collapsed_seed_text() -> String:
	if seed_text.length() <= collapsed_character_count:
		return seed_text
	return seed_text.left(collapsed_character_count) + ".."


func _apply_value_label_width(visible_text: String, animate: bool) -> void:
	var font := value_label.get_theme_font("font")
	var font_size := value_label.get_theme_font_size("font_size")
	var wrapped_text := _wrap_text_for_width(visible_text, font, font_size)
	value_label.text = wrapped_text
	var target_width := _wrapped_text_width(wrapped_text, font, font_size)
	value_label.custom_minimum_size.y = _wrapped_text_height(
		wrapped_text, font, font_size
	)
	if is_instance_valid(_resize_tween):
		_resize_tween.kill()
	if (
		not animate
		or not is_inside_tree()
		or resize_animation_duration <= 0.0
		or is_zero_approx(value_label.custom_minimum_size.x)
	):
		value_label.custom_minimum_size.x = target_width
		return
	_resize_tween = create_tween()
	_resize_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_resize_tween.tween_property(
		value_label, "custom_minimum_size:x", target_width,
		resize_animation_duration
	)


func _wrap_text_for_width(text: String, font: Font, font_size: int) -> String:
	if expanded_label_width <= 0.0 or text.is_empty():
		return text
	if (
		font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		<= expanded_label_width
	):
		return text
	var lines: Array[String] = []
	var line := ""
	for index in text.length():
		var next_line := line + text.substr(index, 1)
		if (
			not line.is_empty()
			and font.get_string_size(
				next_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
			).x > expanded_label_width
		):
			lines.append(line)
			line = text.substr(index, 1)
		else:
			line = next_line
	if not line.is_empty():
		lines.append(line)
	return "\n".join(lines)


func _wrapped_text_width(text: String, font: Font, font_size: int) -> float:
	var width := 0.0
	for line in text.split("\n"):
		width = maxf(width, ceilf(font.get_string_size(
			line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
		).x))
	return width


func _wrapped_text_height(text: String, font: Font, font_size: int) -> float:
	var line_count := maxi(text.split("\n").size(), 1)
	return ceilf(font.get_height(font_size) * line_count)

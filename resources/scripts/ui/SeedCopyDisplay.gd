class_name SeedCopyDisplay
extends HBoxContainer

const BASE_BLUE := Color("4d82c2")
const HIGHLIGHT_BLUE := Color("6da7e5")

@export_range(1, 80, 1) var collapsed_character_count := 5:
	set(value):
		collapsed_character_count = maxi(value, 1)
		if is_node_ready():
			_refresh_visible_seed(false)
@export_range(0.0, 1.0, 0.01, "suffix:s") var resize_animation_duration := 0.18

@onready var seed_icon: TextureRect = %SeedIcon
@onready var value_label: Label = %ValueLabel
@onready var copy_button: TextureButton = %CopyButton

var seed_text := ""
var _highlighted := false
var _resize_tween: Tween


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
	_set_highlight(false)


func set_seed(value: String) -> void:
	seed_text = value
	tooltip_text = value
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
	value_label.add_theme_color_override("font_color", color)
	copy_button.self_modulate = icon_tint
	_refresh_visible_seed()


func _refresh_visible_seed(animate := true) -> void:
	if not is_instance_valid(value_label):
		return
	var visible_text := (
		seed_text
		if _highlighted
		else seed_text.left(collapsed_character_count)
	)
	value_label.text = visible_text
	var font := value_label.get_theme_font("font")
	var font_size := value_label.get_theme_font_size("font_size")
	var target_width := ceilf(font.get_string_size(
		visible_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x)
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

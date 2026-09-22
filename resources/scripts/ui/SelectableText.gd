@tool
class_name SelectableText
extends Button

@export var use_checkbox := true:
	set(value):
		use_checkbox = value
		_refresh_style()
@export var text_hover_offset := Vector2(2.0, 0.0):
	set(value):
		text_hover_offset = value
		_refresh_style()
@export var text_offset := Vector2.ZERO:
	set(value):
		text_offset = value
		_layout_children()
		_refresh_style()
@export var checkbox_offset := Vector2.ZERO:
	set(value):
		checkbox_offset = value
		_layout_children()
		_refresh_style()
@export var fit_select_zone_to_content := true:
	set(value):
		fit_select_zone_to_content = value
		_last_content_size = Vector2.ZERO
		_refresh_content_size()
@export var content_min_height := 24.0:
	set(value):
		content_min_height = maxf(value, 0.0)
		_last_content_size = Vector2.ZERO
		_refresh_style()
@export var normal_text_color := Color("3c3c3c"):
	set(value):
		normal_text_color = value
		_refresh_style()
@export var selected_text_color := Color("4d82c2"):
	set(value):
		selected_text_color = value
		_refresh_style()
@export var checked_uses_selected_text_color := true:
	set(value):
		checked_uses_selected_text_color = value
		_refresh_style()
@export var disabled_text_color := Color("8a8882"):
	set(value):
		disabled_text_color = value
		_refresh_style()

@onready var checkbox_sprite: TextureRect = get_node_or_null("CheckboxSprite")
@onready var text_label: Label = get_node_or_null("TextLabel")

var _checked_texture: Texture2D
var _unchecked_texture: Texture2D
var _empty_texture: Texture2D
var _last_text := ""
var _last_button_pressed := false
var _last_disabled := false
var _last_hovered := false
var _last_focused := false
var _last_content_size := Vector2.ZERO
var _base_minimum_size := Vector2.ZERO
var _base_checkbox_position := Vector2.ZERO
var _base_text_position := Vector2.ZERO
var _resizing_content := false


func _ready() -> void:
	toggle_mode = true
	_base_minimum_size = custom_minimum_size
	if checkbox_sprite != null:
		_base_checkbox_position = checkbox_sprite.position
	if text_label != null:
		_base_text_position = text_label.position
	if checkbox_sprite != null and _unchecked_texture == null:
		_unchecked_texture = checkbox_sprite.texture
	if not toggled.is_connected(_on_toggled):
		toggled.connect(_on_toggled)
	var hover_in := _on_hover_changed.bind(true)
	var hover_out := _on_hover_changed.bind(false)
	if not mouse_entered.is_connected(hover_in):
		mouse_entered.connect(hover_in)
	if not mouse_exited.is_connected(hover_out):
		mouse_exited.connect(hover_out)
	if not focus_entered.is_connected(_on_focus_changed):
		focus_entered.connect(_on_focus_changed)
	if not focus_exited.is_connected(_on_focus_changed):
		focus_exited.connect(_on_focus_changed)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_refresh_style()
	_sync_child_preview(true)


func _process(_delta: float) -> void:
	_hide_native_button_content()
	_sync_child_preview()


func setup(
	has_checkbox: bool,
	font: Font,
	font_size: int,
	checked_texture: Texture2D,
	unchecked_texture: Texture2D,
	base_offset := Vector2.ZERO
) -> void:
	use_checkbox = has_checkbox
	text_offset = base_offset
	_checked_texture = checked_texture
	_unchecked_texture = unchecked_texture
	if font != null:
		add_theme_font_override("font", font)
		if text_label != null:
			text_label.add_theme_font_override("font", font)
	add_theme_font_size_override("font_size", font_size)
	if text_label != null:
		text_label.add_theme_font_size_override("font_size", font_size)
	_refresh_style()


func _refresh_style() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = (
		Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hide_native_button_content()
	add_theme_constant_override("h_separation", 1)
	add_theme_constant_override("check_v_offset", int(round(checkbox_offset.y)))
	var empty := _get_empty_texture()
	add_theme_icon_override("checked", empty)
	add_theme_icon_override("unchecked", empty)
	for state in [&"normal", &"pressed", &"disabled"]:
		add_theme_stylebox_override(state, _empty_style())
	for state in [&"hover", &"hover_pressed", &"focus"]:
		add_theme_stylebox_override(state, _empty_style())
	if checkbox_sprite != null:
		checkbox_sprite.visible = use_checkbox
		checkbox_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		checkbox_sprite.texture = _current_checkbox_texture()
	if text_label != null:
		text_label.visible = true
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		text_label.clip_text = true
		text_label.horizontal_alignment = alignment
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_sync_label_theme()
		text_label.add_theme_color_override("font_color", _current_text_color())
	_refresh_text_label_size()
	_layout_children()
	_sync_child_preview(true)


func _hide_native_button_content() -> void:
	var transparent := Color(1.0, 1.0, 1.0, 0.0)
	for color_name in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color",
		&"font_disabled_color",
	]:
		add_theme_color_override(color_name, transparent)


func _get_empty_texture() -> Texture2D:
	if _empty_texture == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		_empty_texture = ImageTexture.create_from_image(image)
	return _empty_texture


func _current_checkbox_texture() -> Texture2D:
	if not use_checkbox:
		return _get_empty_texture()
	if button_pressed and _checked_texture != null:
		return _checked_texture
	if not button_pressed and _unchecked_texture != null:
		return _unchecked_texture
	return _get_empty_texture()


func _current_text_color() -> Color:
	if disabled:
		return disabled_text_color
	if _last_hovered or has_focus():
		return selected_text_color
	if button_pressed and checked_uses_selected_text_color:
		return selected_text_color
	return normal_text_color


func _sync_child_preview(force := false) -> void:
	var focused := has_focus()
	if (
		not force
		and _last_text == text
		and _last_button_pressed == button_pressed
		and _last_disabled == disabled
		and _last_hovered == is_hovered()
		and _last_focused == focused
	):
		_refresh_content_size()
		return
	_last_text = text
	_last_button_pressed = button_pressed
	_last_disabled = disabled
	_last_hovered = is_hovered()
	_last_focused = focused
	if checkbox_sprite != null:
		checkbox_sprite.visible = use_checkbox
		checkbox_sprite.texture = _current_checkbox_texture()
	if text_label != null:
		_sync_label_theme()
		text_label.text = text
		text_label.add_theme_color_override("font_color", _current_text_color())
		_refresh_text_label_size()
	_layout_children()
	_refresh_content_size()


func _sync_label_theme() -> void:
	if text_label == null:
		return
	var font := get_theme_font("font")
	if font != null:
		text_label.add_theme_font_override("font", font)
	text_label.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))


func _refresh_text_label_size() -> void:
	if text_label == null:
		return
	var natural_width := _text_natural_width()
	var available_width := _available_text_width()
	var label_width := natural_width
	if available_width > 0.0 and (
		not fit_select_zone_to_content
		or (size_flags_horizontal & Control.SIZE_EXPAND) != 0
	):
		label_width = available_width
	text_label.custom_minimum_size = Vector2(label_width, 0.0)
	text_label.size.x = label_width
	var label_size := text_label.get_combined_minimum_size()
	label_size.x = label_width
	text_label.custom_minimum_size = label_size
	text_label.size = label_size


func _text_natural_width() -> float:
	if text_label == null:
		return 0.0
	var font := text_label.get_theme_font("font")
	if font == null:
		return text_label.get_combined_minimum_size().x
	return ceilf(font.get_string_size(
		text_label.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		text_label.get_theme_font_size("font_size")
	).x)


func _available_text_width() -> float:
	if text_label == null:
		return 0.0
	var text_left := _base_text_position.x + text_offset.x
	return maxf(size.x - text_left, 0.0)


func _layout_children() -> void:
	var row_height := _content_row_height()
	if checkbox_sprite != null:
		checkbox_sprite.position = Vector2(
			_base_checkbox_position.x + checkbox_offset.x,
			floorf((row_height - checkbox_sprite.size.y) * 0.5)
				+ checkbox_offset.y
		)
	if text_label != null:
		text_label.position = Vector2(
			_base_text_position.x + text_offset.x,
			floorf((row_height - text_label.size.y) * 0.5)
				+ text_offset.y
		)


func _content_row_height() -> float:
	var row_height := content_min_height
	if custom_minimum_size.y > row_height and custom_minimum_size != _last_content_size:
		row_height = custom_minimum_size.y
	return row_height


func _refresh_content_size() -> void:
	if not fit_select_zone_to_content:
		if _base_minimum_size != Vector2.ZERO:
			custom_minimum_size = Vector2(
				maxf(_base_minimum_size.x, custom_minimum_size.x),
				maxf(content_min_height, custom_minimum_size.y)
			)
			size = custom_minimum_size
		return
	_layout_children()
	var bounds := Rect2(Vector2.ZERO, Vector2.ZERO)
	var has_bounds := false
	if checkbox_sprite != null and checkbox_sprite.visible:
		bounds = Rect2(checkbox_sprite.position, checkbox_sprite.size)
		has_bounds = true
	if text_label != null and text_label.visible:
		var label_rect := Rect2(text_label.position, text_label.size)
		bounds = bounds.merge(label_rect) if has_bounds else label_rect
		has_bounds = true
	if not has_bounds:
		return
	var content_size := Vector2(bounds.end.x, maxf(bounds.end.y, _content_row_height())).ceil()
	if content_size == _last_content_size:
		return
	_last_content_size = content_size
	_resizing_content = true
	custom_minimum_size = content_size
	size = content_size
	_resizing_content = false
	if (size_flags_horizontal & Control.SIZE_EXPAND) == 0:
		size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _on_toggled(_pressed: bool) -> void:
	_sync_child_preview(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED:
		_last_disabled = disabled
		_refresh_style()


func _on_hover_changed(hovered: bool) -> void:
	_last_hovered = hovered
	_sync_child_preview(true)


func _on_focus_changed() -> void:
	_sync_child_preview(true)


func _on_resized() -> void:
	if _resizing_content:
		return
	_last_content_size = Vector2.ZERO
	_refresh_text_label_size()
	_layout_children()


func _empty_style() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

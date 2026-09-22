class_name ScreenSizeOptions
extends RefCounted

const SCREEN_SIZE_MODE_CLASSIC := &"classic"
const SCREEN_SIZE_MODE_SEMI_ADAPTIVE := &"semi_adaptive"
const SCREEN_SIZE_MODE_ADAPTIVE := &"adaptive"
const SCREEN_SIZE_MODES: Array[StringName] = [
	SCREEN_SIZE_MODE_CLASSIC,
	SCREEN_SIZE_MODE_SEMI_ADAPTIVE,
	SCREEN_SIZE_MODE_ADAPTIVE,
]
const SCREEN_SIZE_LABELS: Array[String] = [
	"CLASSIC",
	"SEMI ADAPTIVE",
	"ADAPTIVE",
]
const SCREEN_SIZE_SELECTOR_HEIGHT := 31.0
const SCREEN_SIZE_SELECTOR_CONTENT_RIGHT := 18.0
const BUTTON_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/button.tres"
)
const MULTI_SELECTION_ARROW_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/multiselection-arrow.tres"
)


static func set_adaptive_resolution(game: GameManager, adaptive: bool) -> void:
	game._screen_size_mode = (
		SCREEN_SIZE_MODE_ADAPTIVE if adaptive else SCREEN_SIZE_MODE_CLASSIC
	)
	game._adaptive_resolution = game._screen_size_mode == SCREEN_SIZE_MODE_ADAPTIVE
	var config := _load_config(game)
	config.set_value("graphics", "screen_size_mode", game._screen_size_mode)
	config.set_value("graphics", "adaptive_resolution", game._adaptive_resolution)
	config.save(game.AUDIO_CONFIG_PATH)
	apply_resolution(game)


static func set_screen_size_mode(game: GameManager, index: int) -> void:
	var selected_index := clampi(index, 0, SCREEN_SIZE_MODES.size() - 1)
	game._screen_size_mode = SCREEN_SIZE_MODES[selected_index]
	_save_screen_size_mode(game)
	apply_resolution(game)


static func step_screen_size_mode(game: GameManager, direction: int) -> void:
	var selected_index := wrapi(
		_screen_size_mode_index(game) + direction,
		0,
		SCREEN_SIZE_MODES.size()
	)
	game._screen_size_mode = SCREEN_SIZE_MODES[selected_index]
	_save_screen_size_mode(game)
	apply_resolution(game)


static func _save_screen_size_mode(game: GameManager) -> void:
	game._adaptive_resolution = game._screen_size_mode == SCREEN_SIZE_MODE_ADAPTIVE
	var config := _load_config(game)
	config.set_value("graphics", "screen_size_mode", game._screen_size_mode)
	config.set_value("graphics", "adaptive_resolution", game._adaptive_resolution)
	config.save(game.AUDIO_CONFIG_PATH)


static func toggle_true_pixel_art(game: GameManager) -> void:
	game._true_pixel_art_enabled = not game._true_pixel_art_enabled
	var config := _load_config(game)
	config.set_value("graphics", "true_pixel_art", game._true_pixel_art_enabled)
	config.save(game.AUDIO_CONFIG_PATH)
	apply_resolution(game)


static func apply_resolution(game: GameManager) -> void:
	var window := game.get_window()
	_apply_true_pixel_art_mode(game)
	window.content_scale_mode = (
		Window.CONTENT_SCALE_MODE_VIEWPORT
		if game._true_pixel_art_enabled else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	)
	window.content_scale_size = game.LOCKED_VIEWPORT_SIZE
	window.content_scale_aspect = (
		Window.CONTENT_SCALE_ASPECT_EXPAND
		if _uses_expanded_canvas(game) else Window.CONTENT_SCALE_ASPECT_KEEP
	)
	game.adaptive_resolution_button.modulate = Color.WHITE
	game.adaptive_resolution_button.text = ""
	_refresh_screen_size_options(game)
	game.true_pixel_art_button.modulate = Color.WHITE
	game.true_pixel_art_button.icon = (
		game.SELECTED_TEXTURE
		if game._true_pixel_art_enabled else game.UNCHECKED_TEXTURE
	)
	apply_low_resolution_layout(game)
	game.call_deferred("_resize_dust_distribution")


static func apply_low_resolution_layout(game: GameManager) -> void:
	var scale_factor := 1.0
	var offset := Vector2.ZERO
	var canvas_layer_offset := Vector2.ZERO
	var canvas_size := _logical_layout_size(game)
	var game_size := Vector2(game.LOCKED_VIEWPORT_SIZE)
	game.custom_minimum_size = Vector2(game.LOCKED_VIEWPORT_SIZE)
	if game._true_pixel_art_enabled:
		canvas_size = _true_pixel_layout_size(game)
	if _uses_expanded_canvas(game):
		game.custom_minimum_size = canvas_size
	if game._screen_size_mode == SCREEN_SIZE_MODE_ADAPTIVE:
		game_size = canvas_size
	elif _uses_expanded_canvas(game):
		offset = _centered_game_offset(canvas_size, game.LOCKED_VIEWPORT_SIZE)
		if game._true_pixel_art_enabled:
			offset = offset.round()
	_apply_canvas_item(game.gameplay_layer, game_size, offset, scale_factor)
	_apply_control_canvas(game.screens, game_size, offset, scale_factor)
	_fit_full_rect_children(game.screens)
	if game.has_method("_fit_overlay_to_canvas"):
		game.call("_fit_overlay_to_canvas")
	if game.has_method("_fit_splash_background_to_canvas"):
		game.call("_fit_splash_background_to_canvas")
	if is_instance_valid(game.relief_lighting):
		game.relief_lighting.position = offset
		game.relief_lighting.scale = Vector2.ONE * scale_factor
	_apply_canvas_layer_scale(
		game.get_node_or_null("PresentationLayers"),
		canvas_size,
		canvas_layer_offset,
		scale_factor,
		game.splash
	)
	game._fit_quit_popup_to_viewport()
	if game.has_method("_apply_screen_edge_margins"):
		game.call("_apply_screen_edge_margins")


static func _logical_layout_size(game: GameManager) -> Vector2:
	if _uses_expanded_canvas(game):
		return _available_layout_size(game)
	return Vector2(game.LOCKED_VIEWPORT_SIZE)


static func _true_pixel_layout_size(game: GameManager) -> Vector2:
	if not _uses_expanded_canvas(game):
		return Vector2(game.LOCKED_VIEWPORT_SIZE)
	return _available_layout_size(game).floor()


static func _available_layout_size(game: GameManager) -> Vector2:
	var parent_control := game.get_parent() as Control
	if parent_control != null and parent_control.size.x > 0.0 and parent_control.size.y > 0.0:
		return parent_control.size
	return game.get_viewport_rect().size


static func _setup_screen_size_options(game: GameManager) -> void:
	var selector := game.adaptive_resolution_button.get_parent() as HBoxContainer
	if selector == null:
		game.adaptive_resolution_button.text = SCREEN_SIZE_LABELS[_screen_size_mode_index(game)]
		return
	var legacy_choices := game.options_menu.get_node_or_null("ScreenSizeChoices")
	if legacy_choices != null:
		legacy_choices.get_parent().remove_child(legacy_choices)
		legacy_choices.queue_free()
	var arrows := selector.get_node_or_null("ScreenSizeArrows") as Control
	if arrows != null:
		arrows.visible = false
		arrows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.adaptive_resolution_button.visible = false
	game.adaptive_resolution_button.text = ""
	game.adaptive_resolution_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.adaptive_resolution_button.focus_mode = Control.FOCUS_NONE
	var dropdown := selector.get_node_or_null("ScreenSizeModeSelector") as OptionButton
	if dropdown == null:
		dropdown = OptionButton.new()
		dropdown.name = "ScreenSizeModeSelector"
		selector.add_child(dropdown)
		dropdown.item_selected.connect(_on_screen_size_mode_selected.bind(game))
	_style_screen_size_selector(game, dropdown)
	dropdown.clear()
	for index in SCREEN_SIZE_MODES.size():
		dropdown.add_item(SCREEN_SIZE_LABELS[index], index)
		dropdown.get_popup().set_item_as_radio_checkable(index, true)
	_refresh_screen_size_options(game)


static func refresh_screen_size_options(game: GameManager) -> void:
	if (
		game.graphics_options.visible
		and game.adaptive_resolution_button.get_parent().get_node_or_null(
			"ScreenSizeModeSelector"
		) == null
	):
		_setup_screen_size_options(game)
	_refresh_screen_size_options(game)


static func _refresh_screen_size_options(game: GameManager) -> void:
	var selector := game.adaptive_resolution_button.get_parent() as Control
	if selector == null:
		return
	var dropdown := selector.get_node_or_null("ScreenSizeModeSelector") as OptionButton
	if dropdown == null:
		return
	var selected_index := _screen_size_mode_index(game)
	dropdown.visible = game.graphics_options.visible
	dropdown.select(selected_index)
	var popup := dropdown.get_popup()
	for index in popup.item_count:
		popup.set_item_checked(index, index == selected_index)


static func _style_screen_size_selector(game: GameManager, selector: OptionButton) -> void:
	selector.custom_minimum_size = Vector2(0.0, SCREEN_SIZE_SELECTOR_HEIGHT)
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.flat = false
	selector.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	selector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	selector.add_theme_font_override(
		&"font", game.adaptive_resolution_button.get_theme_font(&"font")
	)
	selector.add_theme_font_size_override(
		&"font_size", game.adaptive_resolution_button.get_theme_font_size(&"font_size")
	)
	selector.add_theme_icon_override(&"arrow", MULTI_SELECTION_ARROW_TEXTURE)
	selector.add_theme_constant_override(&"arrow_margin", 7)
	for color_name in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color",
	]:
		selector.add_theme_color_override(color_name, Color.WHITE)
	selector.add_theme_color_override(&"font_disabled_color", Color.WHITE)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		selector.add_theme_stylebox_override(
			state,
			_screen_size_selector_style(SCREEN_SIZE_SELECTOR_CONTENT_RIGHT)
		)
	var popup := selector.get_popup()
	popup.add_theme_font_override(
		&"font", game.adaptive_resolution_button.get_theme_font(&"font")
	)
	popup.add_theme_font_size_override(
		&"font_size", game.adaptive_resolution_button.get_theme_font_size(&"font_size")
	)
	popup.add_theme_color_override(&"font_color", game.OPTION_TEXT_COLOR)
	popup.add_theme_color_override(&"font_hover_color", game.OPTIONS_SELECTED_COLOR)
	popup.add_theme_color_override(&"font_pressed_color", game.OPTIONS_SELECTED_COLOR)
	popup.add_theme_color_override(&"font_focus_color", game.OPTIONS_SELECTED_COLOR)
	popup.add_theme_icon_override(&"radio_checked", game.SELECTED_TEXTURE)
	popup.add_theme_icon_override(&"radio_unchecked", game.UNCHECKED_TEXTURE)
	popup.add_theme_icon_override(&"checked", game.SELECTED_TEXTURE)
	popup.add_theme_icon_override(&"unchecked", game.UNCHECKED_TEXTURE)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("f7f6f2")
	panel.border_color = game.OPTIONS_SELECTED_COLOR
	panel.set_border_width_all(2)
	panel.content_margin_left = 4
	panel.content_margin_right = 4
	panel.content_margin_top = 4
	panel.content_margin_bottom = 4
	popup.add_theme_stylebox_override(&"panel", panel)
	popup.add_theme_stylebox_override(&"hover", StyleBoxEmpty.new())
	popup.add_theme_stylebox_override(&"pressed", StyleBoxEmpty.new())


static func _screen_size_selector_style(content_right := 9.0) -> StyleBoxTexture:
	return PixelUi.button_style(BUTTON_TEXTURE, content_right)


static func _on_screen_size_mode_selected(index: int, game: GameManager) -> void:
	set_screen_size_mode(game, index)


static func _uses_expanded_canvas(game: GameManager) -> bool:
	return game._screen_size_mode in [
		SCREEN_SIZE_MODE_SEMI_ADAPTIVE,
		SCREEN_SIZE_MODE_ADAPTIVE,
	]


static func _screen_size_mode_index(game: GameManager) -> int:
	var index := SCREEN_SIZE_MODES.find(game._screen_size_mode)
	return maxi(index, 0)


static func _centered_game_offset(
	logical_size: Vector2,
	locked_size: Vector2i
) -> Vector2:
	return (logical_size - Vector2(locked_size)) * 0.5


static func _apply_control_canvas(
	control: Control,
	logical_size: Vector2,
	offset: Vector2,
	scale_factor: float
) -> void:
	if not is_instance_valid(control):
		return
	control.position = offset
	control.scale = Vector2.ONE * scale_factor
	control.size = logical_size


static func _apply_canvas_item(
	node: Node,
	logical_size: Vector2,
	offset: Vector2,
	scale_factor: float
) -> void:
	var control := node as Control
	if control != null:
		_apply_control_canvas(control, logical_size, offset, scale_factor)
		return
	var node_2d := node as Node2D
	if node_2d == null:
		return
	node_2d.position = offset
	node_2d.scale = Vector2.ONE * scale_factor


static func _apply_canvas_layer_scale(
	parent: Node,
	logical_size: Vector2,
	offset: Vector2,
	scale_factor: float,
	transition_control: Control
) -> void:
	if not is_instance_valid(parent):
		return
	for child in parent.get_children():
		var layer := child as CanvasLayer
		if layer == null:
			continue
		layer.offset = offset
		layer.scale = Vector2.ONE * scale_factor
		for layer_child in layer.get_children():
			var layer_control := layer_child as Control
			if layer_control == null:
				continue
			# The returning menu keeps the centered Screens rect and its animated
			# position; only permanent overlays fill the entire canvas.
			if layer_control == transition_control:
				continue
			layer_control.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
			layer_control.position = Vector2.ZERO
			layer_control.size = logical_size


static func _fit_full_rect_children(parent: Control) -> void:
	if not is_instance_valid(parent):
		return
	for child in parent.get_children():
		var control := child as Control
		if control == null:
			continue
		if (
			is_zero_approx(control.anchor_left)
			and is_zero_approx(control.anchor_top)
			and is_equal_approx(control.anchor_right, 1.0)
			and is_equal_approx(control.anchor_bottom, 1.0)
		):
			control.offset_left = 0.0
			control.offset_top = 0.0
			control.offset_right = 0.0
			control.offset_bottom = 0.0
			_fit_full_rect_children(control)


static func _apply_true_pixel_art_mode(game: GameManager) -> void:
	var artwork: Variant = game.get_node_or_null("Artwork")
	if is_instance_valid(artwork):
		artwork.set_pixelated_background(game._true_pixel_art_enabled)
	if is_instance_valid(game.background_manager):
		game.background_manager.set_pixelated_backgrounds(
			game._true_pixel_art_enabled
		)


static func _load_config(_game: GameManager) -> ConfigFile:
	return SaveConfig.load_current()

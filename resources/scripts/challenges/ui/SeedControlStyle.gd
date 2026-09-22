class_name SeedControlStyle
extends RefCounted

## Seed input styling and multi-selection popup layout.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func button_style(host: ChallengeSelection, content_right := 9.0) -> StyleBoxTexture:
	return PixelUi.button_style(host.BUTTON_TEXTURE, content_right)


static func style_seed_input(host: ChallengeSelection, input: LineEdit) -> void:
	input.custom_minimum_size = Vector2(0, host.SEED_MENU_HEIGHT)
	input.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	input.add_theme_font_override("font", host.ENTRY_FONT)
	input.add_theme_font_size_override("font_size", 16)
	input.add_theme_color_override("font_color", Color.WHITE)
	input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.62))
	input.add_theme_color_override("caret_color", Color.WHITE)
	input.add_theme_color_override("selection_color", Color("6da7e5"))
	for state in [&"normal", &"focus", &"read_only"]:
		input.add_theme_stylebox_override(state, host._button_style())
	host._connect_seed_control_highlight(input)


static func style_seed_selector(host: ChallengeSelection, selector: OptionButton) -> void:
	selector.custom_minimum_size = Vector2(0, host.SEED_MENU_HEIGHT)
	selector.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	selector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	selector.add_theme_font_override("font", host.ENTRY_FONT)
	selector.add_theme_font_size_override("font_size", 16)
	selector.add_theme_icon_override("arrow", host.MULTI_SELECTION_ARROW_TEXTURE)
	selector.add_theme_constant_override("arrow_margin", 7)
	for color_name in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_focus_color",
	]:
		selector.add_theme_color_override(color_name, Color.WHITE)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		selector.add_theme_stylebox_override(state, host._button_style(18.0))
	var popup := selector.get_popup()
	popup.add_theme_font_override("font", host.ENTRY_FONT)
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", host.TEXT_COLOR)
	popup.add_theme_color_override("font_hover_color", host.SELECTION_TEXT_COLOR)
	popup.add_theme_color_override("font_pressed_color", host.SELECTION_TEXT_COLOR)
	popup.add_theme_color_override("font_focus_color", host.SELECTION_TEXT_COLOR)
	popup.add_theme_color_override("font_separator_color", host.SELECTED_COLOR)
	popup.add_theme_icon_override("radio_checked", host.SELECTED_TEXTURE)
	popup.add_theme_icon_override("radio_unchecked", host.UNCHECKED_TEXTURE)
	popup.add_theme_icon_override("checked", host.SELECTED_TEXTURE)
	popup.add_theme_icon_override("unchecked", host.UNCHECKED_TEXTURE)
	var empty_style := StyleBoxEmpty.new()
	popup.add_theme_stylebox_override("hover", empty_style)
	popup.add_theme_stylebox_override("pressed", empty_style)
	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = Color("f7f6f2")
	popup_panel.border_color = host.SELECTED_COLOR
	popup_panel.set_border_width_all(2)
	popup_panel.content_margin_left = 4
	popup_panel.content_margin_right = 4
	popup_panel.content_margin_top = 4
	popup_panel.content_margin_bottom = 4
	popup.add_theme_stylebox_override("panel", popup_panel)
	popup.about_to_popup.connect(host._style_popup_scrollbar.bind(popup))
	host._connect_seed_control_highlight(selector)


static func style_seed_check(host: ChallengeSelection, check: Button) -> void:
	check.custom_minimum_size = Vector2(0, 24)
	host._style_selectable_check(check, Vector2.ZERO, TextServer.AUTOWRAP_WORD_SMART, true, true)


static func style_multi_check(host: ChallengeSelection, check: Button) -> void:
	var autowrap := (
		TextServer.AUTOWRAP_OFF
		if check.custom_minimum_size.x > 0.0
		else TextServer.AUTOWRAP_WORD_SMART
	)
	host._style_selectable_check(check, Vector2(0.0, 1.0), autowrap, false, false, 1.0)


static func style_selectable_check(
	host: ChallengeSelection,
	check: Button,
	base_offset: Vector2,
	autowrap: TextServer.AutowrapMode,
	include_disabled_color: bool,
	include_disabled_style: bool,
	content_margin_top := 0.0
) -> void:
	if check is SelectableText:
		(check as SelectableText).setup(
			true,
			host.ENTRY_FONT,
			16,
			host._centered_selected_texture,
			host._centered_unchecked_texture,
			base_offset
		)
	check.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	check.autowrap_mode = autowrap
	check.add_theme_font_override("font", host.ENTRY_FONT)
	check.add_theme_font_size_override("font_size", 16)
	check.add_theme_color_override("font_color", host.TEXT_COLOR)
	check.add_theme_color_override("font_hover_color", host.SELECTION_TEXT_COLOR)
	check.add_theme_color_override("font_pressed_color", host.TEXT_COLOR)
	check.add_theme_color_override("font_hover_pressed_color", host.SELECTION_TEXT_COLOR)
	check.add_theme_color_override("font_focus_color", host.SELECTION_TEXT_COLOR)
	if include_disabled_color:
		check.add_theme_color_override("font_disabled_color", host.MUTED_COLOR)
	check.add_theme_icon_override("checked", host._centered_selected_texture)
	check.add_theme_icon_override("unchecked", host._centered_unchecked_texture)
	check.add_theme_constant_override("h_separation", 1)
	var empty_style := StyleBoxEmpty.new()
	empty_style.content_margin_top = content_margin_top
	var states: Array[StringName] = [
		&"normal", &"hover", &"pressed", &"hover_pressed", &"focus",
	]
	if include_disabled_style:
		states.append(&"disabled")
	for state in states:
		check.add_theme_stylebox_override(state, empty_style)


static func create_multi_select_button(host: ChallengeSelection) -> Button:
	var menu := Button.new()
	menu.custom_minimum_size = Vector2(0, host.SEED_MENU_HEIGHT)
	menu.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu.icon = host.MULTI_SELECTION_ARROW_TEXTURE
	menu.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	menu.expand_icon = false
	menu.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	menu.add_theme_font_override("font", host.ENTRY_FONT)
	menu.add_theme_font_size_override("font_size", 16)
	menu.add_theme_constant_override("h_separation", 4)
	for color_name in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_focus_color",
	]:
		menu.add_theme_color_override(color_name, Color.WHITE)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		menu.add_theme_stylebox_override(state, host._button_style(14.0))
	host._connect_seed_control_highlight(menu)
	return menu


static func attach_multi_select_popup(
	host: ChallengeSelection,
	menu: Button, popup_content: VBoxContainer
) -> PopupPanel:
	var popup := PopupPanel.new()
	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = Color("f7f6f2")
	popup_panel.border_color = host.SELECTED_COLOR
	popup_panel.set_border_width_all(2)
	popup_panel.content_margin_left = 4
	popup_panel.content_margin_right = 4
	popup_panel.content_margin_top = 4
	popup_panel.content_margin_bottom = 4
	popup.add_theme_stylebox_override("panel", popup_panel)
	var scroll_container := ScrollContainer.new()
	scroll_container.name = "PopupScroll"
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.add_child(popup_content)
	popup.add_child(scroll_container)
	menu.add_child(popup)
	popup.about_to_popup.connect(host._style_scrollbar.bind(scroll_container))
	return popup


static func show_multi_select_popup(
	host: ChallengeSelection, menu: Button, popup: PopupPanel
) -> void:
	if popup.visible:
		popup.hide()
		return
	var viewport_width := host.get_viewport_rect().size.x
	var viewport_height := host.get_viewport_rect().size.y
	var menu_rect := menu.get_global_rect()
	var open_above := host._popup_has_more_room_above(menu_rect, viewport_height)
	if not open_above:
		await host._scroll_seed_button_to_popup_anchor(menu)
		menu_rect = menu.get_global_rect()
		open_above = host._popup_has_more_room_above(menu_rect, viewport_height)
	var popup_width := minf(menu.size.x, viewport_width - 16.0)
	var available_space := host._popup_available_space(menu_rect, viewport_height, open_above)
	var popup_height := minf(host.SEED_MENU_POPUP_MAX_HEIGHT, maxf(72.0, available_space))
	var popup_scroll := popup.get_node_or_null("PopupScroll") as ScrollContainer
	if popup_scroll != null and popup_scroll.get_child_count() > 0:
		var content := popup_scroll.get_child(0) as Control
		content.custom_minimum_size.x = maxf(popup_width - 24.0, 0.0)
		content.size.x = content.custom_minimum_size.x
		content.queue_sort()
		await host.get_tree().process_frame
		popup_height = minf(
			popup_height,
			content.get_combined_minimum_size().y + 8.0
		)
	var popup_position := (
		menu_rect.position - Vector2(0, popup_height + 2)
		if open_above
		else menu_rect.position + Vector2(0, menu.size.y + 2)
	)
	popup_position.x = clampf(popup_position.x, 8.0, viewport_width - popup_width - 8.0)
	popup.popup(Rect2i(
		Vector2i(popup_position), Vector2i(popup_width, popup_height)
	))


static func popup_has_more_room_above(
	host: ChallengeSelection, menu_rect: Rect2, viewport_height: float
) -> bool:
	var above_space := menu_rect.position.y - 8.0
	var below_space := viewport_height - (menu_rect.position.y + menu_rect.size.y + 2.0) - 8.0
	return above_space > below_space


static func popup_available_space(
	host: ChallengeSelection,
	menu_rect: Rect2, viewport_height: float, open_above: bool
) -> float:
	if open_above:
		return maxf(menu_rect.position.y - 8.0, 0.0)
	return maxf(
		viewport_height - (menu_rect.position.y + menu_rect.size.y + 2.0) - 8.0,
		0.0
	)


static func scroll_seed_button_to_popup_anchor(host: ChallengeSelection, menu: Button) -> void:
	if host.seed_page == null or not host.seed_page.visible:
		return
	var menu_top := menu.global_position.y - host.seed_page.global_position.y
	var target := host.seed_page.scroll_vertical + menu_top - 2.0
	var max_scroll := host.seed_page.get_v_scroll_bar().max_value
	target = clampf(target, 0.0, max_scroll)
	var tween := host.create_tween()
	tween.tween_property(host.seed_page, "scroll_vertical", int(target), 0.12)
	await tween.finished


static func prepare_centered_check_textures(host: ChallengeSelection) -> void:
	host._centered_selected_texture = host._centered_check_texture(host.SELECTED_TEXTURE)
	host._centered_unchecked_texture = host._centered_check_texture(host.UNCHECKED_TEXTURE)


static func centered_check_texture(host: ChallengeSelection, source: Texture2D) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(Vector2.ZERO, source.get_size())
	return atlas


static func style_popup_scrollbar(host: ChallengeSelection, popup: PopupMenu) -> void:
	await host.get_tree().process_frame
	for child in popup.find_children("*", "VScrollBar", true, false):
		host._style_v_scrollbar(child as VScrollBar)


static func connect_seed_control_highlight(host: ChallengeSelection, control: Control) -> void:
	control.mouse_entered.connect(host._set_seed_control_highlight.bind(control, true))
	control.mouse_exited.connect(host._on_seed_control_mouse_exited.bind(control))
	control.focus_entered.connect(host._set_seed_control_highlight.bind(control, true))
	control.focus_exited.connect(host._set_seed_control_highlight.bind(control, false))


static func on_seed_control_mouse_exited(host: ChallengeSelection, control: Control) -> void:
	if not control.has_focus():
		host._set_seed_control_highlight(control, false)


static func set_seed_control_highlight(
	host: ChallengeSelection, control: Control, highlighted: bool
) -> void:
	control.material = host.challenges_tab_button.highlight_material if highlighted else null

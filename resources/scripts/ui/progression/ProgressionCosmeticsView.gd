class_name ProgressionCosmeticsView
extends RefCounted

## Font/palette choices and the live tile preview.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func populate_fonts(host: ProgressionMenu) -> void:
	var fonts: Array = host._snapshot.get("fonts", [])
	var palettes: Array = host._snapshot.get("palettes", [])
	var preview_data: Dictionary = {}
	var ordered_fonts := fonts
	if Engine.is_editor_hint():
		ordered_fonts = host._selected_first(fonts)
	for font_value in ordered_fonts:
		var font_data := font_value as Dictionary
		var unlocked := bool(font_data.get("unlocked", false))
		if unlocked and (preview_data.is_empty() or bool(font_data.get("selected", false))):
			preview_data = font_data
		if not host._matches_progress_filter(unlocked):
			continue
		var selected := bool(font_data.get("selected", false))
		host._add_cosmetic_choice(
			host.fonts_content,
			str(font_data.get("title", "FONT")),
			unlocked,
			selected,
			host._select_font.bind(StringName(font_data.get("id", &""))),
			font_data.get("font") as Font,
			[],
			int(font_data.get(
				"title_font_size",
				font_data.get("font_size", host.entry_heading_font_size)
			)),
			host._vector2_or_zero(font_data.get("title_font_offset"))
		)
	var ordered_palettes := palettes
	if Engine.is_editor_hint():
		ordered_palettes = host._selected_first(palettes)
	for palette_value in ordered_palettes:
		var palette_data := palette_value as Dictionary
		var palette_unlocked := bool(palette_data.get("unlocked", false))
		var palette_selected_now := bool(palette_data.get("selected", false))
		if palette_selected_now:
			preview_data["colors"] = palette_data.get("colors", [])
		if not host._matches_progress_filter(palette_unlocked):
			continue
		host._add_cosmetic_choice(
			host.palettes_content,
			str(palette_data.get("title", "PALETTE")),
			palette_unlocked,
			palette_selected_now,
			host._select_palette.bind(StringName(palette_data.get("id", &""))),
			null,
			palette_data.get("colors", []) as Array
		)
	host._update_font_preview(preview_data)


static func selected_first(host: ProgressionMenu, entries: Array) -> Array:
	var ordered: Array = []
	for entry_value in entries:
		if bool((entry_value as Dictionary).get("selected", false)):
			ordered.append(entry_value)
	for entry_value in entries:
		if not bool((entry_value as Dictionary).get("selected", false)):
			ordered.append(entry_value)
	return ordered


static func vector2_or_zero(host: ProgressionMenu, value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	return Vector2.ZERO


static func add_cosmetic_choice(
	host: ProgressionMenu,
	target: VBoxContainer,
	title: String,
	unlocked: bool,
	selected: bool,
	selection: Callable,
	choice_font: Font = null,
	palette_colors: Array = [],
	choice_font_size := -1,
	choice_font_offset := Vector2.ZERO
) -> void:
	var use_choice_font := unlocked and choice_font != null
	var displayed_font := choice_font if use_choice_font else host.entry_heading_font
	var displayed_font_size := (
		choice_font_size
		if use_choice_font and choice_font_size > 0
		else host.entry_heading_font_size
	)
	var button := host.SELECTABLE_TEXT_SCENE.instantiate() as SelectableText
	button.setup(
		true, displayed_font, displayed_font_size,
		host.SELECTED_TEXTURE, host.UNCHECKED_TEXTURE
	)
	button.custom_minimum_size.y = 24.0
	button.set_meta("progression_wrap_width", 0.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.fit_select_zone_to_content = false
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.flat = true
	var displayed_title := title if unlocked else "???"
	button.text = displayed_title
	button.add_theme_color_override("font_color", Color("3c3c3c"))
	for color_name in [&"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		button.add_theme_color_override(color_name, host.SELECTION_TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", Color("3c3c3c"))
	button.modulate = Color.WHITE
	button.disabled = not unlocked
	host.PixelUiScript.set_interactive_cursor(button, unlocked)
	if selected:
		# The active cosmetic stays checked until a different choice refreshes
		# the list with the new selection.
		button.button_group = ButtonGroup.new()
		button.button_group.allow_unpress = false
	button.set_pressed_no_signal(selected)
	if unlocked and not selected:
		button.pressed.connect(selection)
	target.add_child(button)
	if not palette_colors.is_empty():
		host._add_palette_title(button, displayed_title, palette_colors, displayed_font)
	elif use_choice_font:
		host._add_font_title(
			button,
			displayed_title,
			displayed_font,
			displayed_font_size,
			choice_font_offset
		)


static func add_font_title(
	host: ProgressionMenu,
	button: Button, title: String, font: Font, font_size: int, font_offset: Vector2
) -> void:
	button.text = ""
	if button is SelectableText:
		(button as SelectableText).text_label.visible = false
	var label := Label.new()
	label.name = "FontTitle"
	label.set_meta("progression_wrap_width", 0.0)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 18.0 + font_offset.x
	label.offset_right += font_offset.x
	label.offset_top += font_offset.y
	label.offset_bottom += font_offset.y
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.use_parent_material = true
	label.text = title
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("3c3c3c"))
	button.add_child(label)
	button.resized.connect(host._resize_font_choice.bind(button, label, font_offset))
	host._connect_choice_title_highlight(button, label)
	host.call_deferred("_resize_font_choice", button, label, font_offset)


static func add_palette_title(
	host: ProgressionMenu,
	button: Button, title: String, colors: Array, font: Font
) -> void:
	button.text = ""
	if button is SelectableText:
		(button as SelectableText).text_label.visible = false
	var label := RichTextLabel.new()
	label.name = "PaletteTitle"
	label.set_meta("progression_wrap_width", 0.0)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 18.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.fit_content = false
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.use_parent_material = true
	if font != null:
		label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", host.entry_heading_font_size)
	label.set_meta("palette_colors", colors.duplicate())
	label.set_meta("palette_title", title)
	for index in title.length():
		label.push_color(colors[index % colors.size()] as Color)
		label.add_text(title.substr(index, 1))
		label.pop()
	button.add_child(label)
	button.resized.connect(host._resize_palette_choice.bind(button, label))
	host._connect_choice_title_highlight(button, label)
	host.call_deferred("_resize_palette_choice", button, label)


static func connect_choice_title_highlight(
	host: ProgressionMenu, button: Button, label: Control
) -> void:
	button.mouse_entered.connect(host._set_choice_title_highlight.bind(label, true))
	button.mouse_exited.connect(host._set_choice_title_highlight.bind(label, false))
	button.focus_entered.connect(host._set_choice_title_highlight.bind(label, true))
	button.focus_exited.connect(host._set_choice_title_highlight.bind(label, false))


static func set_choice_title_highlight(
	host: ProgressionMenu, label: Control, highlighted: bool
) -> void:
	if not is_instance_valid(label):
		return
	if label is Label:
		(label as Label).add_theme_color_override(
			"font_color", host.SELECTION_TEXT_COLOR if highlighted else Color("3c3c3c")
		)
	elif label is RichTextLabel:
		var rich_label := label as RichTextLabel
		var colors: Array = rich_label.get_meta("palette_colors", [])
		if colors.is_empty():
			return
		rich_label.clear()
		var title := rich_label.name
		if rich_label.has_meta("palette_title"):
			title = String(rich_label.get_meta("palette_title"))
		for index in title.length():
			var color := colors[index % colors.size()] as Color
			rich_label.push_color(
				host.SELECTION_TEXT_COLOR if highlighted else color
			)
			rich_label.add_text(title.substr(index, 1))
			rich_label.pop()


static func resize_palette_choice(
	host: ProgressionMenu, button: Button, label: RichTextLabel
) -> void:
	if not is_instance_valid(button) or not is_instance_valid(label):
		return
	# The full-rect anchors already give the label its final wrapped width.
	var required_height := maxf(
		24.0,
		ceilf(label.get_content_height()) + 4.0
	)
	if not is_equal_approx(button.custom_minimum_size.y, required_height):
		button.custom_minimum_size.y = required_height


static func resize_font_choice(
	host: ProgressionMenu, button: Button, label: Label, font_offset: Vector2
) -> void:
	if not is_instance_valid(button) or not is_instance_valid(label):
		return
	label.custom_minimum_size.x = maxf(button.size.x - label.position.x, 0.0)
	var label_height := label.get_combined_minimum_size().y
	var required_height := maxf(
		24.0,
		ceilf(label_height + absf(font_offset.y) * 2.0 + 4.0)
	)
	if not is_equal_approx(button.custom_minimum_size.y, required_height):
		button.custom_minimum_size.y = required_height


static func update_font_preview(host: ProgressionMenu, font_data: Dictionary) -> void:
	for child in host.font_preview.get_children():
		host.font_preview.remove_child(child)
		child.queue_free()
	if font_data.is_empty():
		return
	var font := font_data.get("font") as Font
	var font_size := int(font_data.get("font_size", 20))
	var font_offset := host._vector2_or_zero(font_data.get("font_offset"))
	var override_hidden_tile := true
	var override_hidden_value: Variant = font_data.get(
		"override_hidden_tile_with_font", true
	)
	if override_hidden_value is bool:
		override_hidden_tile = override_hidden_value
	var colors: Array = font_data.get("colors", [])
	var maximum_value := clampi(
		int(host._snapshot.get("max_discovered_tile_value", 3)), 0, 9
	)
	var preview_values: Array[Variant] = ["?"]
	for value in range(maximum_value + 1):
		preview_values.append(value)
	for preview_index in preview_values.size():
		var value: Variant = preview_values[preview_index]
		var is_hidden_tile := preview_index == 0
		var tile := TextureRect.new()
		tile.custom_minimum_size = Vector2(34.0, 37.0)
		tile.texture = (
			host.TILE_FACE_TEXTURE if is_hidden_tile and override_hidden_tile
			else host.TILE_BACK_TEXTURE if is_hidden_tile
			else host.TILE_FACE_TEXTURE
		)
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.stretch_mode = TextureRect.STRETCH_SCALE
		if is_hidden_tile and not override_hidden_tile:
			host.font_preview.add_child(tile)
			continue
		var tile_material := host.font_preview_tile_material.duplicate() as ShaderMaterial
		var color_index := int(value) if not is_hidden_tile else 0
		var tile_color: Color = (
			Color("b8b8b8")
			if is_hidden_tile
			else colors[color_index % colors.size()]
			if not colors.is_empty()
			else host.Settings.TILE_COLORS[color_index % host.Settings.TILE_COLORS.size()]
		)
		tile_material.set_shader_parameter("tile_color", tile_color)
		tile.material = tile_material
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Match the two-pixel optical lift used by Card and Pile value labels.
		label.offset_left = font_offset.x
		label.offset_right = font_offset.x
		label.offset_top = font_offset.y
		label.offset_bottom = font_offset.y - 2.0
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = "?" if is_hidden_tile else str(value)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override(
			"font_color", tile_color if is_hidden_tile else tile_color.darkened(0.35)
		)
		label.add_theme_font_size_override("font_size", font_size)
		if font != null:
			label.add_theme_font_override("font", font)
		tile.add_child(label)
		host.font_preview.add_child(tile)


static func select_font(host: ProgressionMenu, font_id: StringName) -> void:
	host.font_selected.emit(font_id)


static func select_palette(host: ProgressionMenu, palette_id: StringName) -> void:
	host.palette_selected.emit(palette_id)

class_name ProgressionEntryBuilder
extends RefCounted

## Progression rows, status icons and completion bars.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func add_entry(
	host: ProgressionMenu,
	heading: String,
	details: String,
	accent := false,
	status_texture: Texture2D = null,
	muted := false,
	status_text := "",
	gold_status := false,
	progress_ratio := -1.0,
	progress_tooltip := "",
	is_new := false
) -> void:
	var entry := VBoxContainer.new()
	entry.custom_minimum_size.x = 0.0
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_theme_constant_override("separation", 1)
	var heading_row := HBoxContainer.new()
	heading_row.custom_minimum_size.x = 0.0
	heading_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_theme_constant_override("separation", 3)
	if is_new:
		var new_label := Label.new()
		new_label.name = "NewLabel"
		new_label.text = "NEW"
		new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if host.entry_details_font != null:
			new_label.add_theme_font_override("font", host.entry_details_font)
		new_label.add_theme_font_size_override("font_size", host.entry_details_font_size)
		new_label.add_theme_color_override("font_color", host.SELECTED_COLOR)
		heading_row.add_child(new_label)
	if status_texture != null:
		var status_icon := TextureRect.new()
		status_icon.custom_minimum_size = Vector2(12.0, 13.0)
		status_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_icon.texture = status_texture
		status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		status_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		status_icon.modulate.a = host.LOCKED_ENTRY_OPACITY if muted else 1.0
		if gold_status:
			var shader: Shader = host.GOLD_STATUS_SHADER
			var material := ShaderMaterial.new()
			material.shader = shader
			status_icon.material = material
		heading_row.add_child(status_icon)
		if not status_text.is_empty():
			var level_label := Label.new()
			level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			level_label.offset_left += host.bonus_level_text_offset.x
			level_label.offset_right += host.bonus_level_text_offset.x
			level_label.offset_top += host.bonus_level_text_offset.y
			level_label.offset_bottom += host.bonus_level_text_offset.y
			level_label.text = status_text
			level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if host.bonus_level_font != null:
				level_label.add_theme_font_override("font", host.bonus_level_font)
			elif host.entry_details_font != null:
				level_label.add_theme_font_override("font", host.entry_details_font)
			level_label.add_theme_font_size_override("font_size", host.bonus_level_font_size)
			level_label.add_theme_color_override("font_color", Color.WHITE)
			status_icon.add_child(level_label)
	elif not status_text.is_empty():
		var status_label := Label.new()
		status_label.text = status_text
		status_label.custom_minimum_size.x = 31.0
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if host.entry_details_font != null:
			status_label.add_theme_font_override("font", host.entry_details_font)
		status_label.add_theme_font_size_override(
			"font_size", host.entry_details_font_size
		)
		status_label.add_theme_color_override("font_color", host.SELECTED_COLOR)
		status_label.modulate.a = host.LOCKED_ENTRY_OPACITY if muted else 1.0
		heading_row.add_child(status_label)
	var heading_label := Label.new()
	heading_label.text = heading
	heading_label.set_meta("progression_wrap_width", 18.0)
	heading_label.custom_minimum_size.x = 0.0
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if host.entry_heading_font != null:
		heading_label.add_theme_font_override("font", host.entry_heading_font)
	heading_label.add_theme_font_size_override("font_size", host.entry_heading_font_size)
	var heading_offset_style := StyleBoxEmpty.new()
	heading_offset_style.content_margin_left = host.entry_heading_text_offset.x
	heading_offset_style.content_margin_top = host.entry_heading_text_offset.y
	heading_label.add_theme_stylebox_override("normal", heading_offset_style)
	heading_label.add_theme_color_override(
		"font_color",
		Color("4d82c2") if accent else Color("3c3c3c")
	)
	heading_label.modulate.a = host.LOCKED_ENTRY_OPACITY if muted else 1.0
	var details_label := Label.new()
	details_label.text = details
	details_label.set_meta("progression_wrap_width", 0.0)
	details_label.custom_minimum_size.x = 0.0
	details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if host.entry_details_font != null:
		details_label.add_theme_font_override("font", host.entry_details_font)
	details_label.add_theme_font_size_override("font_size", host.entry_details_font_size)
	details_label.add_theme_color_override("font_color", Color("8a8882"))
	details_label.modulate.a = host.LOCKED_ENTRY_OPACITY if muted else 1.0
	heading_row.add_child(heading_label)
	entry.add_child(heading_row)
	entry.add_child(details_label)
	if progress_ratio >= 0.0:
		host._add_progress_bar(entry, progress_ratio, progress_tooltip)
	host.content.add_child(entry)


static func add_progress_bar(
	host: ProgressionMenu,
	entry: VBoxContainer, progress_ratio: float, progress_tooltip: String
) -> void:
	var bar := NinePatchRect.new()
	bar.set_script(host.ProgressionCompletionBarScript)
	bar.custom_minimum_size.y = 6.0
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.texture = host.PROGRESS_BAR_TEXTURE
	bar.patch_margin_left = 2
	bar.patch_margin_top = 2
	bar.patch_margin_right = 2
	bar.patch_margin_bottom = 2
	bar.mouse_default_cursor_shape = Control.CURSOR_HELP
	bar.tooltip_text = progress_tooltip
	bar.set("progress_hint", progress_tooltip)
	var shader: Shader = host.PROGRESS_BAR_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("progress", clampf(progress_ratio, 0.0, 1.0))
	bar.material = material
	bar.mouse_entered.connect(host._set_progress_bar_highlight.bind(material, true))
	bar.mouse_exited.connect(host._set_progress_bar_highlight.bind(material, false))
	entry.add_child(bar)


static func set_progress_bar_highlight(
	host: ProgressionMenu,
	material: ShaderMaterial, highlighted: bool
) -> void:
	material.set_shader_parameter("highlighted", 1.0 if highlighted else 0.0)

extends SceneTree

const ProgressionMenuScene := preload(
	"res://resources/scenes/ProgressionMenu.tscn"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu := ProgressionMenuScene.instantiate() as ProgressionMenu
	root.add_child(menu)
	await process_frame
	var navigation := menu.get_node("Margin/Layout/Body/Navigation") as VBoxContainer
	assert(navigation.custom_minimum_size.x == 30.0)
	assert(
		(menu.content.get_parent() as MarginContainer)
		.get_theme_constant("margin_right") == 10
	)
	assert(menu.get_available_fonts().size() == FontRegistry.create_all().size())
	assert(menu.get_available_fonts().size() == FontRegistry.create_all().size())
	assert(menu.get_available_palettes().size() == 35)
	var palette_ids: Array[StringName] = []
	assert(AchievementRegistry.create_all().size() == 30)
	for achievement in AchievementRegistry.create_all():
		assert(achievement.resource_path.begins_with("res://resources/achievements/"))
	for font_data in menu.get_available_fonts():
		assert(font_data.resource_path.begins_with("res://resources/fonts/data/"))
		if font_data.required_achievement != null:
			assert(font_data.required_achievement.resource_path.begins_with(
				"res://resources/achievements/"
			))
	for palette_data in menu.get_available_palettes():
		assert(palette_data.resource_path.begins_with("res://resources/palettes/"))
		assert(not palette_data.id.is_empty())
		assert(not palette_ids.has(palette_data.id))
		palette_ids.append(palette_data.id)
		if palette_data.required_achievement != null:
			assert(palette_data.required_achievement.resource_path.begins_with(
				"res://resources/achievements/"
			))
	var styled_scrollbar := menu.main_scroll.get_v_scroll_bar()
	assert(is_equal_approx(styled_scrollbar.custom_minimum_size.x, 8.0))
	assert(styled_scrollbar.get_theme_stylebox("grabber") is StyleBoxEmpty)
	var scroll_visual := styled_scrollbar.get_node("ScrollVisual") as ProgressionScrollVisual
	assert(scroll_visual.selector.texture == menu.VERTICAL_SCROLL_SELECTOR_TEXTURE)
	assert(scroll_visual.selector.size == Vector2(6.0, 14.0))
	assert(is_equal_approx(scroll_visual.selector.position.x, 1.0))
	menu.editor_preview_tile_count = 12
	assert(menu.editor_preview_tile_count == 10)
	menu.editor_preview_tile_count = 9
	assert(menu.editor_preview_font != null)
	assert(menu.editor_preview_font.id == &"press_start_2p")
	assert(menu.editor_preview_palette != null)
	assert(menu.editor_preview_palette.id == &"arcade")
	assert(menu.get_achievements().size() == AchievementRegistry.create_all().size())
	var tiny5 := menu.get_available_fonts()[1]
	assert(tiny5.required_achievement != null)
	assert(tiny5.required_achievement.id == &"complete_10_rounds")
	var font_achievement_ids: Array[StringName] = []
	for font_data in menu.get_available_fonts():
		if font_data.required_achievement == null:
			continue
		assert(not font_achievement_ids.has(font_data.required_achievement.id))
		font_achievement_ids.append(font_data.required_achievement.id)
	var pixel_western := menu.get_available_fonts().filter(
		func(data: FontData) -> bool: return data.id == &"pixel_western"
	).front() as FontData
	assert(pixel_western.tile_font_size == 8)
	var upheaval := menu.get_available_fonts().filter(
		func(data: FontData) -> bool: return data.id == &"upheaval"
	).front() as FontData
	assert(upheaval.tile_font_size == 14)
	var snapshot := {
		"max_discovered_tile_value": 8,
		"highscores": [
			{"title": "CLASSIC", "value": "12 rounds left"},
			{"title": "ENDLESS", "value": "round 24"},
			{"title": "CHECKPOINTS", "value": "8 rounds left"},
		],
		"achievements": [
			{
				"title": "FIRST STEPS",
				"description": "Complete a round.",
				"hidden": false,
				"category": &"ROUNDS",
				"unlocked": true,
				"progress": "Rounds completed: 6 / 10",
				"progress_current": 6,
				"progress_target": 10,
			},
			{
				"title": "PERFECT ROUND",
				"description": "Complete a perfect round.",
				"hidden": true,
				"category": &"ROUNDS",
				"unlocked": false,
			},
		],
		"bonuses": [
			{
				"title": "OPEN BOOK",
				"description": "Visible.",
				"seen": true,
				"discovered": true,
				"highest_level": 2,
				"max_level": 3,
			},
			{
				"title": "REDRAW", "description": "Hidden.", "seen": true,
				"discovered": true, "highest_level": 0, "max_level": 3,
			},
		],
		"special_rules": [
			{"title": "SHELL GAME", "description": "Moving.", "discovered": true, "obtained": false},
			{"title": "LIGHTS OUT", "description": "Dark.", "discovered": true, "obtained": true},
		],
		"fonts": [
			{
				"id": &"default", "title": "DEFAULT", "unlocked": true,
				"selected": true, "font": menu.entry_heading_font,
			},
			{"id": &"other", "title": "OTHER", "unlocked": true, "selected": false},
		],
		"palettes": [
			{
				"id": &"test",
				"title": "TEST",
				"colors": [
					Color.RED, Color.ORANGE, Color.YELLOW,
					Color.GREEN, Color.CYAN, Color.BLUE,
					Color.PURPLE, Color.PINK, Color.BROWN,
				],
				"unlocked": true,
				"selected": true,
			},
			{
				"id": &"other_palette", "title": "OTHER PALETTE",
				"colors": [], "unlocked": true, "selected": false,
			},
		],
	}
	menu.open(snapshot)
	await process_frame
	assert(menu.visible)
	assert(menu.title_label.text == "HIGHSCORES")
	assert(menu.content.get_child_count() == 3)
	var score_heading_row := menu.content.get_child(0).get_child(0) as HBoxContainer
	var score_heading := score_heading_row.get_child(0) as Label
	assert(score_heading.get_theme_font_size("font_size") == menu.entry_heading_font_size)
	var score_details := menu.content.get_child(0).get_child(1) as Label
	assert(score_details.get_theme_font_size("font_size") == menu.entry_details_font_size)
	var layout := menu.get_node("Margin/Layout") as Control
	assert(layout.get_combined_minimum_size().x <= 232.0)
	assert(layout.get_combined_minimum_size().y <= 296.0)
	assert(menu.get_global_rect().encloses(layout.get_global_rect()))
	var highscores_button := menu.page_buttons[ProgressionMenu.Page.HIGHSCORES]
	assert(highscores_button is TextureHighlightButton)
	highscores_button.set_pointer_hovered(true)
	assert(highscores_button.material == highscores_button.highlight_material)
	highscores_button.set_pointer_hovered(false)
	assert(highscores_button.material == null)
	assert(menu.get_node("%BackButton") is TextureHighlightButton)
	assert(not menu.lock_filter.visible)
	assert(menu.lock_filter.size == Vector2(36.0, 24.0))
	assert(menu.lock_filter.bar.size == Vector2(36.0, 24.0))
	assert(menu.lock_filter.bar.stretch_mode == TextureRect.STRETCH_KEEP_CENTERED)
	assert(menu.lock_filter.mode == ProgressionMenu.ProgressFilter.BOTH)
	assert(
		(menu.lock_filter.bar.material.get_shader_parameter("highlight_color") as Color)
		.is_equal_approx(menu.SELECTED_COLOR)
	)
	assert(
		(menu.lock_filter.selector.material.get_shader_parameter("highlight_color") as Color)
		.is_equal_approx(menu.SELECTED_COLOR)
	)
	assert(is_equal_approx(menu.lock_filter.selector.position.x, 15.0))
	assert(is_equal_approx(menu.lock_filter.selector.position.y, 16.0))
	menu.lock_filter.selector_right_x = 28.0
	menu.lock_filter.set_mode(ProgressionLockFilter.UNLOCKED)
	assert(is_equal_approx(menu.lock_filter.selector.position.x, 28.0))
	menu.lock_filter.set_mode(ProgressionLockFilter.LOCKED)
	assert(is_equal_approx(menu.lock_filter.selector.position.x, 2.0))
	menu.lock_filter.selector_right_x = 30.0
	menu.lock_filter.set_mode(ProgressionLockFilter.BOTH)

	menu._show_page(ProgressionMenu.Page.BONUSES)
	assert(not menu.lock_filter.visible)
	assert(not menu.SHOW_LOCK_FILTER)
	assert(menu.title_label.text == "BONUSES")
	var global_title := menu.get_node("Margin/Layout/Header/Title") as Label
	assert(menu.lock_filter.get_parent() == global_title.get_parent())
	assert(
		menu.lock_filter.get_index() == global_title.get_index() + 1
	)
	assert(menu.content.get_child_count() == 2)
	var known_entry := menu.content.get_child(0) as VBoxContainer
	var known_heading := known_entry.get_child(0) as HBoxContainer
	var known_status := known_heading.get_child(0) as TextureRect
	assert(known_status.texture == menu.UNCHECKED_TEXTURE)
	assert((known_status.get_child(0) as Label).text == "2")
	assert(
		(known_status.get_child(0) as Label).get_theme_font_size("font_size")
		== menu.bonus_level_font_size
	)
	assert(
		(known_status.get_child(0) as Label).get_theme_color("font_color")
		== Color.WHITE
	)
	assert((known_status.get_child(0) as Label).position == menu.bonus_level_text_offset)
	var unknown_entry := menu.content.get_child(1) as VBoxContainer
	var unknown_heading := unknown_entry.get_child(0) as HBoxContainer
	assert((unknown_heading.get_child(0) as TextureRect).texture == menu.UNCHECKED_TEXTURE)
	assert((unknown_heading.get_child(1) as Label).text == "REDRAW")
	assert((unknown_heading.get_child(0) as TextureRect).get_child_count() == 0)
	assert(is_equal_approx(
		(unknown_heading.get_child(0) as TextureRect).modulate.a,
		menu.LOCKED_ENTRY_OPACITY
	))
	assert(is_equal_approx(
		(unknown_heading.get_child(1) as Label).modulate.a,
		menu.LOCKED_ENTRY_OPACITY
	))
	assert(is_equal_approx(
		(unknown_entry.get_child(1) as Label).modulate.a,
		menu.LOCKED_ENTRY_OPACITY
	))
	assert((unknown_entry.get_child(1) as Label).text == "???")
	menu.lock_filter.set_mode(ProgressionMenu.ProgressFilter.UNLOCKED)
	menu._on_filter_selected(ProgressionMenu.ProgressFilter.UNLOCKED)
	assert(is_equal_approx(menu.lock_filter.selector.position.x, 30.0))
	assert(menu.content.get_child_count() == 1)
	assert((menu.content.get_child(0).get_child(0).get_child(1) as Label).text == "OPEN BOOK")
	menu.lock_filter.set_mode(ProgressionMenu.ProgressFilter.LOCKED)
	menu._on_filter_selected(ProgressionMenu.ProgressFilter.LOCKED)
	assert(is_zero_approx(menu.lock_filter.selector.position.x))
	assert(menu.content.get_child_count() == 1)
	assert((menu.content.get_child(0).get_child(0).get_child(1) as Label).text == "REDRAW")
	menu.lock_filter.set_mode(ProgressionMenu.ProgressFilter.BOTH)
	menu._on_filter_selected(ProgressionMenu.ProgressFilter.BOTH)
	menu.lock_filter._set_selector_highlight(true)
	assert(is_equal_approx(
		float(menu.lock_filter.selector.material.get_shader_parameter("highlighted")),
		1.0
	))
	menu._show_page(ProgressionMenu.Page.SPECIAL_RULES)
	var unbeaten_rule := menu.content.get_child(0) as VBoxContainer
	var unbeaten_heading := unbeaten_rule.get_child(0) as HBoxContainer
	assert((unbeaten_heading.get_child(1) as Label).text == "SHELL GAME")
	assert(is_equal_approx(
		(unbeaten_heading.get_child(1) as Label).modulate.a,
		menu.LOCKED_ENTRY_OPACITY
	))
	assert((unbeaten_rule.get_child(1) as Label).text == "???")
	var beaten_rule := menu.content.get_child(1) as VBoxContainer
	assert((beaten_rule.get_child(1) as Label).text == "Dark.")

	menu._show_page(ProgressionMenu.Page.ACHIEVEMENTS)
	assert((menu.content.get_child(0) as Label).text == "ROUNDS")
	var progressive_achievement := menu.content.get_child(1) as VBoxContainer
	assert(not (progressive_achievement.get_child(1) as Label).text.contains("6 / 10"))
	var achievement_bar := progressive_achievement.get_child(2) as NinePatchRect
	assert(achievement_bar.texture == menu.PROGRESS_BAR_TEXTURE)
	assert(achievement_bar.custom_minimum_size.x == 80.0)
	assert(achievement_bar.patch_margin_left == 2)
	assert(achievement_bar.patch_margin_right == 2)
	assert(achievement_bar.tooltip_text == "Rounds completed: 6 / 10")
	var wrapped_hint := achievement_bar._make_custom_tooltip(
		achievement_bar.tooltip_text
	) as Label
	assert(wrapped_hint.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
	wrapped_hint.free()
	assert(is_equal_approx(
		float(achievement_bar.material.get_shader_parameter("progress")), 0.6
	))
	menu._set_progress_bar_highlight(achievement_bar.material as ShaderMaterial, true)
	assert(is_equal_approx(
		float(achievement_bar.material.get_shader_parameter("highlighted")), 1.0
	))
	var locked_achievement := menu.content.get_child(2) as VBoxContainer
	var locked_achievement_heading := locked_achievement.get_child(0) as HBoxContainer
	assert(is_equal_approx(
		(locked_achievement_heading.get_child(0) as TextureRect).modulate.a,
		menu.LOCKED_ENTRY_OPACITY
	))
	assert((locked_achievement.get_child(1) as Label).text == "Hidden achievement")

	var result := {
		"selected_font": &"", "selected_palette": &"", "did_close": false,
	}
	menu.font_selected.connect(
		func(id: StringName) -> void: result.selected_font = id
	)
	menu.palette_selected.connect(
		func(id: StringName) -> void: result.selected_palette = id
	)
	menu._show_page(ProgressionMenu.Page.FONTS)
	assert(not menu.main_scroll.visible)
	assert(menu.cosmetic_lists.visible)
	assert(menu.font_preview_scroll.get_parent() == layout)
	assert(menu.font_preview_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(menu.font_preview_scroll.custom_minimum_size.y >= 37.0)
	var selected_button := menu.fonts_content.get_child(0) as Button
	var other_button := menu.fonts_content.get_child(1) as Button
	assert(selected_button.text == "DEFAULT")
	assert(not selected_button.disabled)
	assert(selected_button is HighlightButton)
	assert(
		selected_button.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
	)
	assert(selected_button.modulate == Color.WHITE)
	assert(selected_button.icon == menu.SELECTED_TEXTURE)
	assert(
		selected_button.get_theme_font("font") == menu.entry_heading_font
	)
	assert(other_button.icon == menu.UNCHECKED_TEXTURE)
	assert(other_button.modulate == Color.WHITE)
	var preview := menu.font_preview
	assert(preview is HFlowContainer)
	assert(preview.get_child_count() == 10)
	assert((preview.get_child(0) as TextureRect).texture == menu.TILE_BACK_TEXTURE)
	assert(preview.get_child(0).get_child_count() == 0)
	assert((preview.get_child(1).get_child(0) as Label).text == "0")
	var last_preview_index := 9
	assert(
		(preview.get_child(last_preview_index).get_child(0) as Label).text
		== "8"
	)
	var first_preview_tile := preview.get_child(1) as TextureRect
	var first_preview_label := first_preview_tile.get_child(0) as Label
	assert(first_preview_tile.custom_minimum_size == Vector2(34.0, 37.0))
	assert(first_preview_tile.texture == menu.TILE_FACE_TEXTURE)
	assert(first_preview_label.get_theme_font_size("font_size") == 20)
	assert(first_preview_label.get_theme_color("font_color") == Color.RED.darkened(0.35))
	assert(is_equal_approx(first_preview_label.offset_bottom, -2.0))
	other_button.pressed.emit()
	assert(result.selected_font == &"other")
	var other_palette_button := menu.palettes_content.get_child(1) as Button
	var selected_palette_button := menu.palettes_content.get_child(0) as Button
	var palette_title := selected_palette_button.get_node("PaletteTitle") as RichTextLabel
	assert(palette_title.get_parsed_text() == "TEST")
	assert(palette_title.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
	assert((palette_title.get_meta("palette_colors") as Array)[0] == Color.RED)
	other_palette_button.pressed.emit()
	assert(result.selected_palette == &"other_palette")
	snapshot["max_discovered_tile_value"] = 4
	menu.refresh(snapshot)
	menu._show_page(ProgressionMenu.Page.FONTS)
	assert(menu.font_preview.get_child_count() == 6)
	assert((menu.font_preview.get_child(5).get_child(0) as Label).text == "4")

	menu.closed.connect(func() -> void: result.did_close = true)
	menu.close()
	assert(result.did_close)
	assert(not menu.visible)
	menu.queue_free()
	print("Progression menu tests passed.")
	quit()

extends SceneTree

const ProgressionMenuScene := preload(
	"res://resources/scenes/progression/ProgressionMenu.tscn"
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
	assert(AchievementRegistry.create_all().size() >= 41)
	for achievement in AchievementRegistry.create_all():
		assert(achievement.resource_path.begins_with("res://resources/data/achievements/"))
	for font_data in menu.get_available_fonts():
		assert(font_data.resource_path.begins_with("res://resources/data/fonts/"))
		if font_data.required_achievement != null:
			assert(font_data.required_achievement.resource_path.begins_with(
				"res://resources/data/achievements/"
			))
	for palette_data in menu.get_available_palettes():
		assert(palette_data.resource_path.begins_with("res://resources/data/palettes/"))
		assert(not palette_data.id.is_empty())
		assert(not palette_ids.has(palette_data.id))
		palette_ids.append(palette_data.id)
		if palette_data.required_achievement != null:
			assert(palette_data.required_achievement.resource_path.begins_with(
				"res://resources/data/achievements/"
			))
	var styled_scrollbar := menu.main_scroll.get_v_scroll_bar()
	assert(is_equal_approx(styled_scrollbar.custom_minimum_size.x, 8.0))
	assert(styled_scrollbar.get_theme_stylebox("grabber") is StyleBoxEmpty)
	var scroll_visual := styled_scrollbar.get_node("ScrollVisual") as ProgressionScrollVisual
	assert(scroll_visual.selector.texture == menu.VERTICAL_SCROLL_SELECTOR_TEXTURE)
	assert(scroll_visual.selector.size == Vector2(6.0, 14.0))
	assert(is_equal_approx(scroll_visual.selector.position.x, 1.0))
	menu.font_catalog.editor_preview_tile_count = 12
	assert(menu.font_catalog.editor_preview_tile_count == 10)
	menu.font_catalog.editor_preview_tile_count = 9
	assert(menu.font_catalog.editor_preview_font != null)
	assert(
		menu.font_catalog.editor_preview_font.id
		== menu.font_catalog.font_data_catalog.get_selected_data().id
	)
	assert(menu.font_catalog.editor_preview_palette != null)
	assert(
		menu.font_catalog.editor_preview_palette.id
		== menu.font_catalog.palette_data_catalog.get_selected_data().id
	)
	assert(menu.get_default_font().id == &"vcr")
	assert(menu.get_default_palette().id == &"arcade")
	menu._copy_notification_placement()
	for badge in menu._page_badges:
		assert(badge.position == Vector2(0.0, 21.0))
		assert(badge.size == Vector2(10.0, 11.0))
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
				"reward_font": &"eight_bit_hud",
				"new": true,
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
			{
				"id": &"other", "title": "PIXELATED PUSAB", "unlocked": true,
				"selected": false, "font": menu.entry_heading_font,
			},
			{
				"id": &"locked", "title": "LOCKED FONT", "unlocked": false,
				"selected": false, "font": menu.entry_details_font,
				"title_font_size": 8,
			},
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
	assert(layout.get_combined_minimum_size().x <= 296.0)
	assert(layout.get_combined_minimum_size().y <= 296.0)
	assert(menu.get_global_rect().encloses(layout.get_global_rect()))
	var body := menu.get_node("Margin/Layout/Body") as HBoxContainer
	var body_minimum_y := body.get_combined_minimum_size().y
	var highscores_button := menu.page_buttons[ProgressionMenu.Page.HIGHSCORES]
	assert(highscores_button is TextureHighlightButton)
	highscores_button.set_pointer_hovered(true)
	assert(highscores_button.material == highscores_button.highlight_material)
	highscores_button.set_pointer_hovered(false)
	assert(highscores_button.material == null)
	assert(menu.get_node("%BackButton") is TextureHighlightButton)
	assert(not menu.lock_filter.visible)
	var lock_main := menu.lock_filter.get_node("IconOffset/LockMain") as TextureRect
	var lock_handle := menu.lock_filter.get_node(
		"IconOffset/HandleFlipAnchor/LockHandle"
	) as TextureRect
	var flip_anchor := menu.lock_filter.get_node(
		"IconOffset/HandleFlipAnchor"
	) as Node2D
	assert(menu.lock_filter.size == Vector2(21.0, 28.0))
	assert(lock_main.texture.resource_path.ends_with("main.png"))
	assert(lock_handle.texture.resource_path.ends_with("handle.png"))
	assert(menu.lock_filter.mode == ProgressionMenu.ProgressFilter.BOTH)
	assert(lock_main.modulate == Color.WHITE)
	assert(lock_handle.modulate == Color.WHITE)
	assert(menu.lock_filter.tooltip_text.is_empty())
	menu.lock_filter.animation_duration = 0.0
	menu.lock_filter.set_mode(ProgressionLockFilter.UNLOCKED)
	assert(lock_main.modulate == Color.WHITE)
	assert(lock_handle.modulate == Color.WHITE)
	assert(flip_anchor.scale.x < 0.0)
	menu.lock_filter.set_mode(ProgressionLockFilter.LOCKED)
	assert(lock_main.modulate == Color.WHITE)
	assert(lock_handle.modulate == Color.WHITE)
	assert(flip_anchor.scale == Vector2.ONE)
	assert(
		lock_handle.position
		== ProgressionLockFilter.HANDLE_BASE_POSITION
			+ menu.lock_filter.locked_handle_offset
	)
	menu.lock_filter.set_mode(ProgressionLockFilter.BOTH)

	menu._show_page(ProgressionMenu.Page.BONUSES)
	assert(menu.lock_filter.visible)
	assert(not menu.font_preview_scroll.visible)
	assert(is_equal_approx(menu.font_preview_scroll.modulate.a, 1.0))
	assert(menu.SHOW_LOCK_FILTER)
	assert(menu.title_label.text == "BONUSES")
	var back_button := menu.get_node("%BackButton") as TextureHighlightButton
	var lock_slot := menu.lock_filter.get_parent() as Control
	assert(lock_slot.get_parent() == back_button.get_parent())
	assert(lock_slot.get_index() == back_button.get_index() - 1)
	assert(lock_slot.size_flags_vertical == Control.SIZE_SHRINK_CENTER)
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
	assert((known_heading.get_child(1) as Label).size.y > 1.0)
	assert((known_entry.get_child(1) as Label).size.y > 1.0)
	assert((unknown_heading.get_child(1) as Label).size.y > 1.0)
	assert((unknown_entry.get_child(1) as Label).size.y > 1.0)
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
	assert(flip_anchor.scale.x < 0.0)
	assert(menu.content.get_child_count() == 1)
	assert((menu.content.get_child(0).get_child(0).get_child(1) as Label).text == "OPEN BOOK")
	menu.lock_filter.set_mode(ProgressionMenu.ProgressFilter.LOCKED)
	menu._on_filter_selected(ProgressionMenu.ProgressFilter.LOCKED)
	assert(flip_anchor.scale == Vector2.ONE)
	assert(menu.content.get_child_count() == 1)
	assert((menu.content.get_child(0).get_child(0).get_child(1) as Label).text == "REDRAW")
	menu.lock_filter.set_mode(ProgressionMenu.ProgressFilter.BOTH)
	menu._on_filter_selected(ProgressionMenu.ProgressFilter.BOTH)
	menu.lock_filter._set_selector_highlight(true)
	assert(lock_main.modulate.r > 1.0)
	assert(lock_handle.modulate.r > 1.0)
	menu._show_page(ProgressionMenu.Page.SPECIAL_RULES)
	var unbeaten_rule := menu.content.get_child(0) as VBoxContainer
	var unbeaten_heading := unbeaten_rule.get_child(0) as HBoxContainer
	assert((unbeaten_heading.get_child(1) as Label).text == "SHELL GAME")
	assert((unbeaten_heading.get_child(1) as Label).size.y > 1.0)
	assert(is_equal_approx(
		(unbeaten_heading.get_child(1) as Label).modulate.a,
		menu.LOCKED_ENTRY_OPACITY
	))
	assert((unbeaten_rule.get_child(1) as Label).text == "???")
	assert((unbeaten_rule.get_child(1) as Label).size.y > 1.0)
	var beaten_rule := menu.content.get_child(1) as VBoxContainer
	assert((beaten_rule.get_child(1) as Label).text == "Dark.")
	assert((beaten_rule.get_child(1) as Label).size.y > 1.0)

	menu._show_page(ProgressionMenu.Page.ACHIEVEMENTS)
	assert((menu.content.get_child(0) as Label).text == "ROUNDS")
	var progressive_achievement := menu.content.get_child(1) as VBoxContainer
	var progressive_heading := progressive_achievement.get_child(0) as HBoxContainer
	assert((progressive_heading.get_node("NewLabel") as Label).text == "NEW")
	var achievement_details := progressive_achievement.get_child(1) as Label
	assert(not achievement_details.text.contains("6 / 10"))
	assert(achievement_details.text.contains("Reward: 8-BIT HUD"))
	var achievement_bar := progressive_achievement.get_child(2) as NinePatchRect
	assert(achievement_bar.texture == menu.PROGRESS_BAR_TEXTURE)
	assert(achievement_bar.custom_minimum_size.x == 0.0)
	assert(achievement_bar.size_flags_horizontal == Control.SIZE_EXPAND_FILL)
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
	assert(menu.font_preview_scroll.visible)
	assert(is_equal_approx(menu.font_preview_scroll.modulate.a, 1.0))
	assert(body.get_combined_minimum_size().y >= body_minimum_y)
	assert(menu.font_preview_scroll.get_parent() == layout)
	assert(menu.font_preview_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(menu.font_preview_scroll.custom_minimum_size.y >= 37.0)
	var selected_button := menu.fonts_content.get_child(0) as Button
	var other_button := menu.fonts_content.get_child(1) as Button
	var locked_button := menu.fonts_content.get_child(2) as SelectableText
	var selected_font_title := selected_button.get_node("FontTitle") as Label
	var other_font_title := other_button.get_node("FontTitle") as Label
	assert(selected_font_title.text == "DEFAULT")
	assert(selected_font_title.autowrap_mode == TextServer.AUTOWRAP_OFF)
	assert(selected_font_title.clip_text)
	assert((selected_button as SelectableText).fit_select_zone_to_content == false)
	assert(selected_font_title.size.x > selected_font_title.position.x)
	assert(other_font_title.text == "PIXELATED PUSAB")
	assert(other_font_title.autowrap_mode == TextServer.AUTOWRAP_OFF)
	assert(other_font_title.clip_text)
	assert(other_font_title.size.x > other_font_title.position.x)
	assert(not (selected_button as SelectableText).text_label.visible)
	assert(locked_button.disabled)
	assert(locked_button.text == "???")
	assert(locked_button.get_node_or_null("FontTitle") == null)
	assert(locked_button.text_label.visible)
	assert(locked_button.text_label.text == "???")
	assert(locked_button.text_label.get_theme_font("font") == menu.entry_heading_font)
	var font_title_y := selected_font_title.position.y
	for index in 4:
		await process_frame
		assert(selected_font_title.position.y == font_title_y)
		assert(other_font_title.get_line_count() == 1)
	assert(not selected_button.disabled)
	assert(selected_button is SelectableText)
	assert(
		selected_button.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
	)
	assert(selected_button.modulate == Color.WHITE)
	assert((selected_button as SelectableText).checkbox_sprite.texture == menu.SELECTED_TEXTURE)
	assert(
		selected_font_title.get_theme_font("font") == menu.entry_heading_font
	)
	assert((other_button as SelectableText).checkbox_sprite.texture == menu.UNCHECKED_TEXTURE)
	assert(other_button.modulate == Color.WHITE)
	var preview := menu.font_preview
	assert(preview is HFlowContainer)
	assert(preview.get_child_count() == 10)
	assert((preview.get_child(0) as TextureRect).texture == menu.TILE_FACE_TEXTURE)
	assert((preview.get_child(0).get_child(0) as Label).text == "?")
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

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
	var snapshot := {
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
				"unlocked": true,
			},
			{
				"title": "PERFECT ROUND",
				"description": "Complete a perfect round.",
				"hidden": false,
				"unlocked": false,
			},
		],
		"bonuses": [
			{"title": "OPEN BOOK", "description": "Visible.", "discovered": true},
			{"title": "REDRAW", "description": "Hidden.", "discovered": false},
		],
		"special_rules": [{
			"title": "SHELL GAME", "description": "Moving.", "discovered": true,
		}],
		"fonts": [
			{"id": &"default", "title": "DEFAULT", "unlocked": true, "selected": true},
			{"id": &"other", "title": "OTHER", "unlocked": true, "selected": false},
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
	assert(not menu.filter_button.visible)

	menu._show_page(ProgressionMenu.Page.BONUSES)
	assert(menu.filter_button.visible)
	assert(menu.title_label.text == "BONUSES")
	assert(menu.content.get_child_count() == 2)
	var known_entry := menu.content.get_child(0) as VBoxContainer
	var known_heading := known_entry.get_child(0) as HBoxContainer
	assert((known_heading.get_child(0) as TextureRect).texture == menu.CHECKED_TEXTURE)
	var unknown_entry := menu.content.get_child(1) as VBoxContainer
	var unknown_heading := unknown_entry.get_child(0) as HBoxContainer
	assert((unknown_heading.get_child(0) as TextureRect).texture == menu.UNCHECKED_TEXTURE)
	assert((unknown_heading.get_child(1) as Label).text == "???")
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
	menu.filter_button.select(ProgressionMenu.ProgressFilter.UNLOCKED)
	menu._on_filter_selected(ProgressionMenu.ProgressFilter.UNLOCKED)
	assert(menu.content.get_child_count() == 1)
	assert((menu.content.get_child(0).get_child(0).get_child(1) as Label).text == "OPEN BOOK")
	menu.filter_button.select(ProgressionMenu.ProgressFilter.LOCKED)
	menu._on_filter_selected(ProgressionMenu.ProgressFilter.LOCKED)
	assert(menu.content.get_child_count() == 1)
	assert((menu.content.get_child(0).get_child(0).get_child(1) as Label).text == "???")
	menu.filter_button.select(ProgressionMenu.ProgressFilter.BOTH)
	menu._on_filter_selected(ProgressionMenu.ProgressFilter.BOTH)

	menu._show_page(ProgressionMenu.Page.ACHIEVEMENTS)
	var locked_achievement := menu.content.get_child(1) as VBoxContainer
	var locked_achievement_heading := locked_achievement.get_child(0) as HBoxContainer
	assert(is_equal_approx(
		(locked_achievement_heading.get_child(0) as TextureRect).modulate.a,
		menu.LOCKED_ENTRY_OPACITY
	))

	var result := {"selected_font": &"", "did_close": false}
	menu.font_selected.connect(
		func(id: StringName) -> void: result.selected_font = id
	)
	menu._show_page(ProgressionMenu.Page.FONTS)
	var selected_entry := menu.content.get_child(0) as VBoxContainer
	var other_entry := menu.content.get_child(1) as VBoxContainer
	var selected_button := selected_entry.get_child(0) as HighlightButton
	var other_button := other_entry.get_child(0) as Button
	assert(selected_button.text == "DEFAULT")
	assert(selected_button.disabled)
	assert(selected_button.modulate == menu.SELECTED_COLOR)
	assert(selected_button.get_theme_stylebox("normal") == menu.font_button_style)
	assert(other_button is HighlightButton)
	assert(other_button.modulate == Color.WHITE)
	var preview := menu.font_preview
	assert(preview.get_child_count() == 9)
	assert((preview.get_child(0).get_child(0) as Label).text == "1")
	assert((preview.get_child(8).get_child(0) as Label).text == "9")
	var first_preview_tile := preview.get_child(0) as TextureRect
	var first_preview_label := first_preview_tile.get_child(0) as Label
	assert(first_preview_tile.custom_minimum_size == Vector2(34.0, 37.0))
	assert(first_preview_tile.texture == menu.TILE_FACE_TEXTURE)
	assert(first_preview_label.get_theme_font_size("font_size") == 20)
	assert(first_preview_label.get_theme_color("font_color") == menu.Settings.TILE_COLORS[1].darkened(0.35))
	other_button.pressed.emit()
	assert(result.selected_font == &"other")
	menu.font_preview_tile_count = 4
	menu._show_page(ProgressionMenu.Page.FONTS)
	assert(menu.font_preview.get_child_count() == 4)
	assert((menu.font_preview.get_child(3).get_child(0) as Label).text == "4")

	menu.closed.connect(func() -> void: result.did_close = true)
	menu.close()
	assert(result.did_close)
	assert(not menu.visible)
	menu.queue_free()
	print("Progression menu tests passed.")
	quit()

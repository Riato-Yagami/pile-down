extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(50).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	var menu := game.progression_menu
	var snapshot := game._progression_snapshot()
	menu.open(snapshot)
	menu._show_page(ProgressionMenu.Page.FONTS)
	await process_frame
	var updated := snapshot.duplicate(true)
	updated["fonts"].append({"id": &"cache_new", "title": "NEW FONT", "unlocked": true, "selected": false})
	menu.refresh(updated)
	await process_frame
	await process_frame
	menu.hide()
	await process_frame
	await process_frame
	assert(not menu.cosmetic_builds[0]["running"])
	var first := menu.fonts_content.get_child(0)
	menu.open(updated)
	while menu.cosmetic_builds[0]["running"]:
		await process_frame
	assert(menu.fonts_content.get_child(0) == first, "Resume a partial list without rebuilding existing rows")
	assert(menu.fonts_content.get_child_count() == updated["fonts"].size(), "A cancelled generation must not add stale or duplicated rows")
	for frame in 3:
		await process_frame
	for row in menu.fonts_content.get_children():
		assert(row.size.x >= menu.fonts_content.size.x - 1.0, "Expanded font rows must retain the container width across processing frames")
		var title := row.get_node_or_null("FontTitle") as Label
		if title != null:
			assert(is_equal_approx(title.get_rect().end.x, row.size.x + title.offset_right), "Font titles must use the full row width")
	var tabs := menu.cosmetic_lists as CustomisationTabs
	tabs.select_tab(1, false)
	while menu.cosmetic_builds[1]["running"]:
		await process_frame
	menu.lock_filter.set_mode(ProgressionLockFilter.LOCKED, true)
	while menu.cosmetic_builds[1]["running"]:
		await process_frame
	var locked_count := 0
	for palette: Dictionary in updated["palettes"]:
		if not palette.get("unlocked", false):
			locked_count += 1
	assert(menu.palettes_content.get_child_count() == locked_count)
	menu.lock_filter.set_mode(ProgressionLockFilter.BOTH, true)
	while menu.cosmetic_builds[1]["running"]:
		await process_frame
	TranslationServer.set_locale("fr")
	menu.refresh(updated)
	while menu.cosmetic_builds[1]["running"]:
		await process_frame
	for index in updated["palettes"].size():
		var button := menu.palettes_content.get_child(index)
		if button.has_node("PaletteTitle"):
			var expected_title: String = String(TranslationServer.translate(updated["palettes"][index]["title"])) if updated["palettes"][index].get("unlocked", false) else "???"
			assert(button.get_node("PaletteTitle").get_meta("palette_title") == expected_title)
	# Selecting cosmetics must retain both the rows and their scroll position.
	menu.lock_filter.set_mode(ProgressionLockFilter.BOTH, true)
	for tab in [0, 1, 2]:
		tabs.select_tab(tab, false)
		while bool(menu.cosmetic_builds.get(tab, {}).get("running", false)):
			await process_frame
		for frame in 3:
			await process_frame
		var content := menu.fonts_content if tab == 0 else menu.palettes_content if tab == 1 else menu.values_content
		var scroll := menu.fonts_scroll if tab == 0 else menu.palettes_scroll if tab == 1 else menu.values_scroll
		var first_row := content.get_child(0)
		scroll.scroll_vertical = 80
		await process_frame
		var position := scroll.scroll_vertical
		var changed := updated.duplicate(true)
		if tab < 2:
			var key := "fonts" if tab == 0 else "palettes"
			for index in changed[key].size():
				changed[key][index]["selected"] = index == 1
		else:
			changed["selected_value_style"] = &"dots"
		menu.refresh(changed)
		for frame in 3:
			await process_frame
		assert(content.get_child(0) == first_row, "Selection must reuse existing rows")
		assert(scroll.scroll_vertical == position, "Selection must preserve scrolling")
		if tab < 2:
			assert((content.get_child(1) as Button).button_pressed)
	game.queue_free()
	await process_frame
	await process_frame
	print("Customisation cache passed: cancelled generation, partial resume, filter and locale invalidation, cleanup.")
	quit()

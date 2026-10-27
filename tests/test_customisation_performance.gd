extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	for font in game.font_manager.definitions:
		if not game.font_manager.unlocked.has(font.id):
			game.font_manager.unlocked.append(font.id)
	game.value_style_manager.achievements.append(&"a_to_z")
	game.value_style_manager.achievements.append(&"joker_trio")
	game.max_discovered_tile_value = 9
	var menu := game.progression_menu
	menu.open(game._progression_snapshot())
	var opening: Array[float] = []
	for iteration in 4:
		menu._show_page(ProgressionMenu.Page.HIGHSCORES)
		var started := Time.get_ticks_usec()
		menu._show_page(ProgressionMenu.Page.FONTS)
		opening.append((Time.get_ticks_usec() - started) / 1000.0)
		await process_frame
		await process_frame
	while bool(menu.cosmetic_builds.get(0, {}).get("running", false)):
		await process_frame
	var first_font_row := menu.fonts_content.get_child(0)
	(menu.cosmetic_lists as CustomisationTabs).select_tab(2, false)
	var first_value_row := menu.values_content.get_child(0)
	var first_preview_tile := menu.font_preview.get_child(1)
	var switching: Array[float] = []
	for style in [&"letters", &"dots", &"numbers", &"dots", &"letters"]:
		var started := Time.get_ticks_usec()
		game.value_style_manager.select(style)
		switching.append((Time.get_ticks_usec() - started) / 1000.0)
		await process_frame
		await process_frame
	assert(menu.fonts_content.get_child(0) == first_font_row)
	assert(menu.values_content.get_child(0) == first_value_row)
	assert(menu.font_preview.get_child(1) == first_preview_tile)
	var result := {"open_ms": opening, "switch_ms": switching, "font_count": game.font_manager.unlocked.size()}
	var output := OS.get_environment("PILE_DOWN_CUSTOMISATION_BENCHMARK")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify(result, "\t"))
	print("Customisation timings: ", result)
	game.queue_free()
	await process_frame
	quit()

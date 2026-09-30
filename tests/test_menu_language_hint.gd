extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(35.0).timeout.connect(func(): quit(1))
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var game := main.get_node("GameCenter/Game") as GameManager
	var language := root.get_node("LanguageSettings")
	var selector := game.gameplay_options.get_node("LanguageSelector") as OptionButton
	assert(selector.item_count == 2)
	assert(selector.get_theme_color("font_color") == Color.WHITE)
	for locale: String in ["fr", "en", "fr"]:
		language.apply_language(locale, false)
		assert(TranslationServer.translate("PLAY") == ("JOUER" if locale == "fr" else "PLAY"))
		assert(TranslationServer.translate("%d ROUNDS LEFT").contains("MANCHES") == (locale == "fr"))
		for frame in 3:
			await process_frame
		var skip := game.bonus_selection.skip_button
		var text_width := skip.get_theme_font("font").get_string_size(
			skip.tr(skip.text), HORIZONTAL_ALIGNMENT_LEFT, -1,
			skip.get_theme_font_size("font_size")
		).x
		var padding := skip.get_theme_stylebox("normal").get_minimum_size().x
		assert(skip.size.x >= text_width + padding, "Skip button clips its translated text")
	assert(game.overlay.is_ancestor_of(game.end_seed_display))
	assert(not game._show_end_seed)
	assert(not game.end_seed_display.visible)
	game.end_seed_button.pressed.emit()
	assert(game._show_end_seed and game.end_seed_display.visible)
	assert(SaveConfig.load_current().get_value("gameplay", "show_end_seed", false))
	game.end_seed_button.pressed.emit()
	assert(not game._show_end_seed and not game.end_seed_display.visible)
	assert(game.end_seed_display.seed_text == game.run_seed_label)
	for pixel_art: bool in [false, true]:
		game._screen_size_mode = &"adaptive"
		game._true_pixel_art_enabled = pixel_art
		game.GameOptionsControllerScript.apply_resolution(game)
		for window_size: Vector2i in [Vector2i(1600, 900), Vector2i(752, 640), Vector2i(900, 1600)]:
			root.size = window_size
			for frame in 8:
				await process_frame
			assert(game.gameplay_layer.size.is_equal_approx(game.get_viewport_rect().size.floor()))
			assert(game.size.is_equal_approx(game.get_viewport_rect().size.floor()))
			assert(game.splash.size.is_equal_approx(game.size))
			assert(game.splash.get_global_rect().position.is_equal_approx(game.global_position))
	game._screen_size_mode = &"menu_adaptive"
	game.GameOptionsControllerScript.apply_resolution(game)
	for frame in 8:
		await process_frame
	game.splash.reparent(game.menu_transition_layer)
	await game._play_return_to_menu_transition()
	assert(game.splash.size.is_equal_approx(game.size))
	game.splash.reparent(game.screens)
	game._restore_splash_screen_layout()
	assert(game.splash.get_global_rect().position.is_equal_approx(game.global_position))
	game.splash.hide()
	game.gameplay_layer.show()
	game.input_locked = false
	var pile := preload("res://resources/scenes/gameplay/Pile.tscn").instantiate() as MemoryPile
	game.piles_board.add_child(pile)
	pile.current_value = 5
	game.piles.append(pile)
	var card := preload("res://resources/scenes/gameplay/Card.tscn").instantiate() as PlayingCard
	game.hand_container.add_child(card)
	card.card_value = 4
	# HandManager enumerates its tracked cards rather than arbitrary children.
	game.hand_manager.current_cards.append(card)
	await process_frame
	await process_frame
	assert(game.first_move_hint.visible)
	game.card_placed.emit(card, pile)
	await process_frame
	assert(not game.first_move_hint.visible)
	assert(game.first_move_hint.completed)
	main.queue_free()
	await process_frame
	print("Menu, language and first move hint tests passed.")
	quit()

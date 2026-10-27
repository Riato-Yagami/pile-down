extends "res://tests/test_seed_replay.gd"


func _run() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	for value in 10:
		assert(TilePips.PATTERNS[value].size() == value)
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	game.start_game(false, null, false, "VALUES", {}, [&"snake"], {"pile_count": 2, "hand_size": 2, "start_value": 9})
	await _wait_for_hand(game)
	game.timer_manager.stop_countdown()
	game.snake_rule_controller.set_process(false)
	game.hand_manager.finish_all_card_entrances()
	var card := game.hand_manager.current_cards[0]
	var pile := game.piles[0]
	card.card_value = 7
	pile.current_value = 8
	pile.face_up = true
	game.max_discovered_tile_value = 9
	game.value_style_manager.achievements.append(&"a_to_z")
	game.value_style_manager.achievements.append(&"joker_trio")
	var config := SaveConfig.load_current()
	config.set_value("progression", "unlocked_achievements", [&"joker_trio"])
	config.save(SaveConfig.PATH)
	var menu := game.progression_menu
	menu.open(game._progression_snapshot())
	menu._show_page(ProgressionMenu.Page.FONTS)
	var tabs := menu.cosmetic_lists as CustomisationTabs
	tabs.select_tab(2, false)
	assert(menu.values_content.get_child_count() == 4)
	assert(menu.values_scroll.visible)
	TranslationServer.set_locale("fr")
	for viewport_size in [Vector2i(256, 320), Vector2i(636, 323)]:
		root.size = viewport_size
		for frame in 6:
			await process_frame
		assert(tabs.tabs.get_tab_rect(2).end.x <= tabs.tabs.size.x + 0.1, "All three customisation tabs must fit")
	var letters := menu.values_content.get_child(1) as Button
	letters.pressed.emit()
	assert(game.value_style_manager.selected_style == &"letters")
	assert(card.value_label.text == "H" and pile.value_label.text == "I")
	assert(menu.font_preview.get_child(1).get_child(0).text == "A")
	assert(menu.font_preview.get_child(10).get_child(0).text == "J")
	(menu.values_content.get_child(2) as Button).pressed.emit()
	assert(game.value_style_manager.selected_style == &"dots")
	assert(card.value_label.text.is_empty())
	assert((card.value_label.get_node("ValuePips") as TilePips).value == 7)
	assert((pile.value_label.get_node("ValuePips") as TilePips).value == 8)
	assert(menu.font_preview.get_child(8).get_child(0).get_node("ValuePips").value == 7)
	var current_pips := card.value_label.get_node("ValuePips") as TilePips
	var tiny_font := preload("res://resources/fonts/Tiny5-Regular.ttf")
	card.set_value_font(tiny_font, 20)
	assert(current_pips.dot_font == tiny_font)
	var glyph := TilePips.dot_glyph(current_pips.dot_font, current_pips.dot_font_size)
	assert(glyph["font"] == current_pips.dot_font)
	assert(is_same(glyph, TilePips.dot_glyph(current_pips.dot_font, current_pips.dot_font_size)))
	assert(TilePips.dot_glyph(FontFile.new(), 16)["font"] == TilePips.BASE_FONT)
	var missing := FontFile.new()
	missing.fallbacks = [preload("res://resources/fonts/Tiny5-Regular.ttf")]
	assert(TilePips.dot_glyph(missing, 16)["font"] == TilePips.BASE_FONT)
	var saved := ValueStyleManager.new()
	saved.load_progress()
	assert(saved.selected_style == &"dots")
	assert(not saved.select(&"bad_style"))
	saved.free()
	# Masking, jokers and Roman Holiday retain their own meaning.
	card.flip_down(false)
	assert(not (card.value_label.get_node("ValuePips") as TilePips).visible)
	assert(card.value_label.text == "?")
	card.flip_up(false)
	card.set_joker(true)
	assert(card.value_label.text == "J")
	assert(not (card.value_label.get_node("ValuePips") as TilePips).visible)
	card.set_joker(false)
	card.roman_numerals_enabled = true
	card._update_appearance()
	assert(card.value_label.text == "VII")
	assert(not (card.value_label.get_node("ValuePips") as TilePips).visible)
	game.round_modifiers.value_style = &"roman"
	pile.set_value_style(&"roman")
	pile.roman_numerals_enabled = true
	pile._refresh()
	card._update_appearance()
	assert(card.value_label.text == "7" and pile.value_label.text == "8")
	assert(card.value_label.get_theme_font_size("font_size") == card._value_font_size)
	card.flip_down(false)
	assert(card.value_label.text == "?")
	card.flip_up(false)
	card.set_joker(true)
	assert(card.value_label.text == "J")
	card.set_joker(false)
	card.roman_numerals_enabled = false
	pile.roman_numerals_enabled = false
	card._update_appearance()
	pile._refresh()
	assert(card.value_label.text == "VII" and pile.value_label.text == "VIII")
	game.round_modifiers.value_style = &"dots"
	pile.set_value_style(&"dots")
	game.round_modifiers.hide_tile_numbers = true
	card._update_appearance()
	assert(not card.value_label.is_visible_in_tree())
	game.round_modifiers.hide_tile_numbers = false
	card._update_appearance()
	game.snake_rule_controller._animate_meal(card)
	var copy := game.snake_rule_controller._meal_visuals[0].get_child(0).get_node("ValueLabel/ValuePips") as TilePips
	assert(copy != null and copy.value == 7 and copy.visible)
	assert(copy.dot_font == tiny_font)
	var glow := preload("res://resources/scripts/special_rules/rules/TileAfterglow.gd").new()
	game.flashlight_overlay.add_child(glow)
	game.flashlight_overlay.show()
	glow.setup(card.face_sprite, card.back_sprite, card.value_label)
	card.flip_down(false)
	glow._process(0.0)
	assert(not glow._copies[2].get_node("ValuePips").visible, "Afterglow must not reveal hidden dots")
	game.start_game(false, null, false, "VALUES-NEXT", {}, [&"snake"], {"pile_count": 2})
	await _wait_for_hand(game)
	assert(game.round_modifiers.value_style == &"dots")
	assert(game.piles[0].value_style == &"dots")
	game.queue_free()
	await process_frame
	print("Value styles passed: tabs, letters, dots 0-9, preview, persistence, masking, joker, Roman, Snake and afterglow.")
	quit()

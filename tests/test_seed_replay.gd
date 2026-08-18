extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.splash.visible = false
	game.start_game(
		false, null, false, "REPLAY-INPUT-SEED",
		{&"redraw": 2}, [&"shell_game"]
	)
	await _wait_for_hand(game)
	var first_values := _hand_values(game)
	assert(game.run_uses_requested_seed)
	assert(game.run_seed_label == "REPLAY-INPUT-SEED")
	assert(game.bonus_manager.has_bonus(&"redraw"))
	assert(game.bonus_manager.level(&"redraw") == 2)
	assert(game.special_rule_manager.forced_rule_ids.has(&"shell_game"))
	game._open_quit_popup()
	assert(game.pause_seed_display.visible)
	await process_frame
	assert(
		game.quit_panel.get_global_rect().encloses(
			game.pause_seed_display.get_global_rect()
		)
	)
	assert(game.pause_seed_display.copy_button.texture_normal != null)
	assert(game.pause_seed_display.value_label.text == "REPLA")
	game.pause_seed_display.collapsed_character_count = 7
	assert(game.pause_seed_display.value_label.text == "REPLAY-")
	game.pause_seed_display.collapsed_character_count = 5
	# Headless builds have no clipboard, so expose Copy to validate its layout.
	game.pause_seed_display.copy_button.visible = true
	game.pause_seed_display._set_highlight(true)
	assert(game.pause_seed_display.value_label.text == "REPLAY-INPUT-SEED")
	await create_timer(
		game.pause_seed_display.resize_animation_duration + 0.05
	).timeout
	assert(absf(
		game.pause_seed_display.copy_button.position.x
		- game.pause_seed_display.value_label.position.x
		- game.pause_seed_display.value_label.size.x - 4.0
	) <= 1.0)
	assert(
		game.pause_seed_display.value_label.get_theme_color("font_color")
		== Color("6da7e5")
	)
	game.pause_seed_display._set_highlight(false)
	assert(game.pause_seed_display.value_label.text == "REPLA")
	assert(
		game.pause_seed_display.value_label.get_theme_color("font_color")
		== Color("4d82c2")
	)
	game._close_quit_popup()
	await game._restart_current_mode()
	await _wait_for_hand(game)
	assert(game.run_seed_label == "REPLAY-INPUT-SEED")
	assert(game.run_uses_requested_seed)
	assert(_hand_values(game) == first_values)
	assert(game.bonus_manager.has_bonus(&"redraw"))
	assert(game.bonus_manager.level(&"redraw") == 2)
	assert(game.special_rule_manager.forced_rule_ids.has(&"shell_game"))
	print("Seed replay tests passed.")
	game.queue_free()
	quit()


func _wait_for_hand(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while (
		(game.input_locked or game.hand_manager.current_cards.is_empty())
		and Time.get_ticks_msec() < deadline
	):
		await process_frame
	assert(not game.input_locked)
	assert(not game.hand_manager.current_cards.is_empty())


func _hand_values(game: GameManager) -> Array[int]:
	var result: Array[int] = []
	for card in game.hand_manager.current_cards:
		if is_instance_valid(card):
			result.append(card.card_value)
	return result

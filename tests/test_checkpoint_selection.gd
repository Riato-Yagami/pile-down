extends SceneTree

const MainScene := preload("res://resources/scenes/Main.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(40.0).timeout.connect(func() -> void: quit(1))
	var main := MainScene.instantiate()
	root.add_child(main)
	await _settle()
	var game := main.get_node("GameCenter/Game") as GameManager
	game.unlocked_checkpoints.clear()
	game.checkpoint_snapshots.clear()
	game.best_rounds_left = 15
	game.best_score_time_ms = 12345
	game.checkpoint_best_rounds_left = 10
	game._refresh_checkpoint_button()
	assert(not game.checkpoint_button.is_visible_in_tree())
	await _settle()
	var normal_button_height := game.splash_button.size.y
	game._generate_debug_checkpoint_snapshots(3)
	game.selected_checkpoint_id = 0
	game._refresh_checkpoint_button()
	game._show_selected_checkpoint()
	assert(game.selected_checkpoint_id == 0)
	assert(game.checkpoint_button.text.ends_with("0"))
	var normal_score := game.splash_high_score.text
	assert(not normal_score.contains("CHECKPOINT"))
	var normal_time := game.splash_high_score_time.text
	assert(game.splash_high_score_time.visible)
	var activations := {"count": 0}
	game.checkpoint_up_button.pressed.connect(
		func() -> void: activations.count += 1
	)
	for mode in [&"classic", &"menu_adaptive", &"adaptive"]:
		game._screen_size_mode = mode
		game.GameOptionsControllerScript.apply_resolution(game)
		for dimensions in [Vector2i(1080, 2424), Vector2i(2424, 1080)]:
			root.size = dimensions
			await _settle()
			assert(is_equal_approx(game.splash_button.size.y, normal_button_height),
				"Checkpoint touch targets must not stretch the normal play button")
			assert(is_equal_approx(game.checkpoint_button.size.y, normal_button_height),
				"Checkpoint buttons must retain the normal button height")
			var button_rect := game.checkpoint_button.get_global_rect()
			var up_rect := game.checkpoint_up_button.get_global_rect()
			var down_rect := game.checkpoint_down_button.get_global_rect()
			assert(up_rect.position.y >= button_rect.position.y - 0.01,
				"The up arrow must stay within the button height")
			assert(down_rect.end.y <= button_rect.end.y + 0.01,
				"The down arrow must stay within the button height")
			assert(not up_rect.intersects(down_rect),
				"Arrow click areas must not overlap")
			assert(not up_rect.intersects(button_rect) and not down_rect.intersects(button_rect),
				"Arrow click areas must stay separate from the checkpoint button")
			assert(game.checkpoint_down_button.disabled)
			for checkpoint_id in [1, 2, 3]:
				var previous_count: int = activations.count
				# Tap the padding around the sprite through the real viewport.
				await _tap(game.checkpoint_up_button, Vector2(2, 2))
				assert(activations.count == previous_count + 1,
					"A touch must select exactly one checkpoint")
				assert(game.selected_checkpoint_id == checkpoint_id,
					"Touch must select every unlocked checkpoint in %s" % mode)
				assert(game.checkpoint_button.text.ends_with(str(checkpoint_id * 5)))
				assert(not game.splash_high_score_time.visible)
				assert(game.splash_high_score.text.contains("CHECKPOINT"))
			assert(game.checkpoint_up_button.disabled)
			await _tap(game.checkpoint_up_button)
			assert(game.selected_checkpoint_id == 3)
			for checkpoint_id in [2, 1, 0]:
				await _tap(game.checkpoint_down_button, Vector2(2, 2))
				assert(game.selected_checkpoint_id == checkpoint_id)
			assert(game.checkpoint_down_button.disabled)
			await _tap(game.checkpoint_down_button)
			assert(game.selected_checkpoint_id == 0)
			assert(game.splash_high_score.text == normal_score)
			assert(game.splash_high_score_time.text == normal_time)
			assert(game.splash_high_score_time.visible)
			game._refresh_checkpoint_button()
			assert(game.selected_checkpoint_id == 0)
	var language := root.get_node("LanguageSettings")
	var original_locale: String = language.preference
	for locale in ["en", "fr"]:
		language.apply_language(locale, false)
		game.selected_checkpoint_id = 1
		for best in [-1, 10]:
			game.checkpoint_best_rounds_left = best
			game._show_selected_checkpoint()
			assert(game.splash_high_score.get_parsed_text().begins_with(
				"RECORD CHECKPOINT" if locale == "fr" else "CHECKPOINT HIGHSCORE"
			))
		game.selected_checkpoint_id = 0
		game._show_selected_checkpoint()
		assert(not game.splash_high_score.text.contains("CHECKPOINT"))
	language.apply_language(original_locale, false)
	game.checkpoint_best_rounds_left = 10
	game._select_next_checkpoint(1)
	var down := InputEventKey.new()
	down.pressed = true
	down.keycode = KEY_DOWN
	game._on_checkpoint_button_input(down)
	assert(game.selected_checkpoint_id == 0)
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	game._on_checkpoint_button_input(wheel)
	assert(game.selected_checkpoint_id == 1)
	await _tap(game.checkpoint_button)
	await _wait_until_unlocked(game)
	assert(game.game_mode == GameManager.GameMode.CHECKPOINT)
	assert(game.started_from_checkpoint)
	assert(game.current_checkpoint_id == 1)
	assert(game.round_number == DifficultySettings.CHECKPOINT_INTERVAL)
	await game._return_to_menu()
	await _settle()
	await _tap(game.checkpoint_down_button)
	assert(game.selected_checkpoint_id == 0)
	await _tap(game.checkpoint_button)
	await _wait_until_unlocked(game)
	assert(game.game_mode == GameManager.GameMode.STANDARD)
	assert(not game.started_from_checkpoint)
	assert(game.current_checkpoint_id == 0)
	assert(game.checkpoint_bonus_backlog == 0)
	assert(game.run_start_round == 1)
	assert(game.round_number == DifficultySettings.TOTAL_ROUNDS)
	assert(game.pile_count == DifficultySettings.START_PILES)
	assert(game.hand_size == DifficultySettings.START_HAND_SIZE)
	assert(game.start_value == DifficultySettings.START_CARD_VALUE)
	assert(game.turn_time == DifficultySettings.START_TURN_TIME)
	# Debug starts intentionally grant the configured starting bonuses.
	if not DebugSettings.is_enabled():
		assert(game.bonus_manager.active.is_empty())
	game._save_checkpoint_progress()
	main.queue_free()
	await process_frame
	main = MainScene.instantiate()
	root.add_child(main)
	await _settle()
	game = main.get_node("GameCenter/Game") as GameManager
	assert(game.selected_checkpoint_id == 3,
		"Opening the game must select the highest saved checkpoint")
	assert(game.checkpoint_button.text.ends_with("15"))
	game.selected_checkpoint_id = 0
	game._refresh_checkpoint_button()
	assert(game.selected_checkpoint_id == 0,
		"Refreshing the menu must preserve an explicit normal start")
	main.queue_free()
	await process_frame
	print("Checkpoint selection tests passed.")
	quit()


func _tap(button: BaseButton, local_point := Vector2(-1, -1)) -> void:
	var point := button.get_global_transform_with_canvas() * (
		button.size * 0.5 if local_point.x < 0 else local_point
	)
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = point
		touch.pressed = pressed
		root.push_input(touch, true)
		await process_frame


func _settle() -> void:
	for frame in 12:
		await process_frame


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

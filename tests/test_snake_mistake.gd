extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(25).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	game.start_game(false, null, false, "SNAKE-MISTAKE", {}, [&"snake"], {"pile_count": 2, "hand_size": 1, "start_value": 5})
	while game.input_locked or game.hand_manager.current_cards.is_empty():
		await process_frame
	var snake := game.snake_rule_controller
	snake.set_process(false)
	snake.step()
	snake._advance_slide(snake._slide_duration * 0.3)
	assert(snake.sliding)
	var pile := snake.segments[0]
	var position_before := pile.global_position
	var elapsed_before := snake._slide_elapsed
	var card := game.hand_manager.current_cards[0]
	card.card_value = 0
	card.dragging = true
	game.selected_card = card
	card.global_position = pile.global_position
	var mistakes := game.run_mistake_count
	game._on_card_drag_released(card, pile.get_global_rect().get_center())
	assert(game.run_mistake_count == mistakes + 1)
	assert(pile._error_shake_tween != null and pile._error_shake_tween.is_running())
	assert(is_equal_approx(snake.mistake_pause_remaining, DifficultySettings.SNAKE_MISTAKE_PAUSE_DURATION))
	assert(not card.dragging)
	# Input may unlock early, but the snake remains stationary throughout feedback.
	game.timer_manager.running = true
	snake._process(DifficultySettings.SNAKE_MISTAKE_PAUSE_DURATION * 0.5)
	assert(pile.global_position == position_before)
	assert(snake._slide_elapsed == elapsed_before)
	snake._process(DifficultySettings.SNAKE_MISTAKE_PAUSE_DURATION * 0.5)
	assert(pile.global_position == position_before)
	assert(snake.mistake_pause_remaining == 0)
	snake._process(0.1)
	assert(snake._slide_elapsed > elapsed_before)
	assert(pile.global_position != position_before)
	# Timer damage leaves an in-progress slide uninterrupted.
	var before_timeout := snake._slide_elapsed
	game.bonus_manager.safety_net_available = false
	game.mistakes_left = 3
	await game._on_time_expired()
	assert(snake.mistake_pause_remaining == 0)
	snake._process(0.05)
	assert(snake._slide_elapsed > before_timeout)
	# A second error renews the full pause; cleanup disconnects the signal.
	game.placement_mistake_made.emit()
	assert(snake.mistake_pause_remaining == DifficultySettings.SNAKE_MISTAKE_PAUSE_DURATION)
	snake.stop()
	assert(snake.mistake_pause_remaining == 0)
	assert(not game.placement_mistake_made.is_connected(snake.pause_after_mistake))
	await create_timer(1.5).timeout
	game.queue_free()
	await process_frame
	print("Snake mistake tests passed: invalid-drop animation, movement pause, resume and cleanup.")
	quit()

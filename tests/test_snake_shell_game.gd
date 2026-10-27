extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(25).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	game.start_game(false, null, false, "SNAKE-ANIMATION", {}, [&"snake", &"shell_game"], {"pile_count": 4, "hand_size": 1, "start_value": 5, "turn_time": 100.0})
	while game.input_locked or game.hand_manager.current_cards.is_empty():
		await process_frame
	var snake := game.snake_rule_controller
	snake.set_process(false)
	game.timer_manager.stop_countdown()
	assert(not (load("res://resources/data/special_rules/20_snake.tres") as SpecialRuleData).incompatible_rules.has(&"shell_game"))
	for round_number in [1, DifficultySettings.THREE_PILE_SHELL_GAME_ROUND]:
		# Include a swap interrupting an unfinished Snake slide.
		snake.step()
		snake._advance_slide(0.05)
		var previous := snake.segments.duplicate()
		var path := snake.cells.duplicate()
		var finished := [false]
		_swap(game, round_number, finished)
		assert(snake._permuting and not snake.sliding)
		while not finished[0]:
			await process_frame
		assert(not snake._permuting)
		assert(snake.cells == path, "Shell Game keeps the continuous body path")
		var moved := 0
		for index in snake.segments.size():
			var pile := snake.segments[index]
			if pile != previous[index]:
				moved += 1
			assert(pile.global_position.is_equal_approx(snake._global_position(path[index])))
			var exchanged_position := pile.global_position
			snake._place_segments()
			assert(pile.global_position.is_equal_approx(exchanged_position), "No snap back after swap")
		assert(moved == (2 if round_number == 1 else 3))
		assert(snake.segments[0].z_index == 20)
		# A subsequent move starts every segment at its exchanged cell.
		snake.step()
		for pile in snake._slide_origins:
			var slot := snake.segments.find(pile)
			assert(snake._slide_origins[pile].is_equal_approx(snake._global_position(path[slot])))
		snake._advance_slide(1.0)
	game.piles[1].completed = true
	await game.special_rule_manager.after_card_played(game.piles, 1)
	for index in snake.segments.size():
		if not snake.segments[index].completed:
			assert(snake.segments[index].global_position.is_equal_approx(snake._global_position(snake.cells[index])))
	game.queue_free()
	await process_frame
	print("Snake Shell Game tests passed: two/three swaps, interrupted slides, completed segment and no snap back.")
	quit()


func _swap(game: GameManager, round_number: int, finished: Array) -> void:
	await game.special_rule_manager.after_card_played(game.piles, round_number)
	finished[0] = true

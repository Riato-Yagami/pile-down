extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(20).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	game.start_game(false, null, false, "SNAKE-MEAL-REROLL", {}, [&"snake"], {"pile_count": 1, "hand_size": 1, "start_value": 5})
	while game.input_locked or game.hand_manager.current_cards.is_empty():
		await process_frame
	var snake := game.snake_rule_controller
	assert(snake.meal_heal_chance == 0.5)
	snake.meal_heal_chance = 1.0
	snake.set_process(false)
	game.timer_manager.stop_countdown()
	var pile := game.piles[0]
	var old_card := game.hand_manager.current_cards[0]
	old_card.finish_entrance_immediately()
	pile.current_value = 3
	old_card.card_value = 2
	snake.cells.assign([Vector2i(0, 0)])
	snake._place_segments()
	snake.card_cells.clear()
	snake.card_cells[old_card] = Vector2i(1, 0)
	old_card.global_position = snake._global_position(Vector2i(1, 0))
	snake.step()
	snake._advance_slide(1)
	assert(pile.current_value == 3, "Healing waits for the digestion wave")
	assert(snake._meal_visuals.size() == 1)
	assert(snake._meal_visuals[0].z_index < pile.z_index)
	for cell in snake._free_cells():
		assert(not snake._cell_overlaps_snake(cell))
	assert(game.timer_manager._freeze_time_left > 0.0)
	for frame in 180:
		await process_frame
		if (not is_instance_valid(old_card) or not game.hand_manager.current_cards.has(old_card)) and not game.input_locked:
			break
	assert((not is_instance_valid(old_card) or not game.hand_manager.current_cards.has(old_card)))
	assert(not game.input_locked, "A snake meal that rerolls the hand must release the input lock")
	assert(pile.current_value == 4)
	assert(game.timer_manager.running)
	assert(game._pending_interactive_generation == -1)
	var card := game.hand_manager.current_cards[0]
	assert(pile.can_accept(card.card_value))
	assert(snake.card_cells.has(card))
	assert(game.get_node("Artwork").z_index < card.z_index, "Board tiles must remain above every background layer")
	assert(card.z_index < pile.z_index)
	game._on_card_drag_started(card)
	assert(card.z_index > pile.z_index)
	card.finish_drag()
	game.selected_card = null
	assert(card.z_index < pile.z_index)
	game.timer_manager.set_process(false)
	var meal_time := game.timer_manager.time_left
	game.timer_manager._process(0.5)
	assert(game.timer_manager.time_left == meal_time)
	var previous := snake.cells[0]
	snake._process(DifficultySettings.SNAKE_STEP_DURATION + 0.1)
	assert(snake.cells[0] != previous and snake.sliding)
	game.queue_free()
	await process_frame
	print("Snake after-meal reroll tests passed: renewed playable hand, input, timer and movement resume.")
	quit()

extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(50).timeout.connect(func(): quit(1))
	var rule := load("res://resources/data/special_rules/20_snake.tres") as SpecialRuleData
	assert(DifficultySettings.is_special_rule_enabled(&"snake"))
	var modifiers := RoundModifiers.new()
	var context := RoundContext.new(8, modifiers)
	rule.activate(context)
	assert(modifiers.snake_enabled)
	rule.deactivate(context)
	assert(not modifiers.snake_enabled)
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	game.start_game(false, null, false, "SNAKE-TEST", {}, [&"snake"], {"pile_count": 4, "hand_size": 4, "start_value": 5})
	while game.input_locked or game.hand_manager.current_cards.is_empty():
		await process_frame
	var snake := game.snake_rule_controller
	assert(snake.meal_heal_chance == 0.5)
	snake.meal_heal_chance = 1.0
	snake.set_process(false)
	game.timer_manager.stop_countdown()
	assert(snake.active)
	assert(snake.cells.size() == 4)
	assert(snake.card_cells.size() == 4)
	var seen: Array[Vector2i] = []
	for cell in snake.cells:
		assert(not seen.has(cell))
		seen.append(cell)
	for card: PlayingCard in snake.card_cells:
		assert(not seen.has(snake.card_cells[card]))
		seen.append(snake.card_cells[card])
		assert(card.hand_return_position().is_equal_approx(card.global_position))
	var tail: MemoryPile = snake.segments.back()
	tail.current_value = 3
	var card: PlayingCard = snake.card_cells.keys()[0]
	var old_cell: Vector2i = snake.card_cells[card]
	var value := card.card_value
	snake._eat(card)
	await create_timer(0.95).timeout
	assert(tail.current_value == 4)
	assert(card.card_value == value)
	assert(snake.card_cells[card] != old_cell)
	snake._eat(card)
	await create_timer(0.95).timeout
	assert(tail.current_value == 5)
	snake._eat(card)
	await create_timer(0.95).timeout
	assert(tail.current_value == 5)
	# A full tail redirects the single heal toward the nearest damaged segment.
	var body := snake.segments[-2]
	body.current_value = 2
	snake._eat(card)
	await create_timer(0.95).timeout
	assert(tail.current_value == 5 and body.current_value == 3)
	# A failed roll still relocates food but does not heal any segment.
	snake.meal_heal_chance = 0.0
	old_cell = snake.card_cells[card]
	snake._eat(card)
	await create_timer(0.95).timeout
	assert(body.current_value == 3)
	assert(snake.card_cells[card] != old_cell)
	snake.meal_heal_chance = 1.0
	tail.completed = true
	var next_tail := snake.segments[-2]
	next_tail.current_value = 2
	snake._eat(card)
	await create_timer(0.95).timeout
	assert(tail.current_value == 5 and next_tail.current_value == 3)
	# A selected/dragged tile is never consumed or teleported.
	game.selected_card = card
	assert(not snake._can_eat(card))
	game.selected_card = null
	card.finish_entrance_immediately()
	# Force a reachable meal one square to the right: chase and consumption
	# must work together, without calling the eating helper directly.
	snake.cells.assign([Vector2i(1, 1), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)])
	snake.card_cells.clear()
	snake.card_cells[card] = Vector2i(2, 1)
	card.global_position = snake._global_position(Vector2i(2, 1))
	card.record_hand_position()
	snake._place_segments()
	snake.meal_pause_remaining = 0.0
	var before := next_tail.current_value
	snake.step()
	snake._advance_slide(1.0)
	assert(snake.cells[0] == Vector2i(2, 1))
	assert(snake.card_cells[card] != Vector2i(2, 1))
	await create_timer(0.95).timeout
	assert(next_tail.current_value == before + 1)
	# Rejected drags return to a square, not the former HBox hand.
	var home := card.hand_return_position()
	card.global_position += Vector2(20, 10)
	await game._return_card_to_hand(card, 0.01)
	assert(card.get_parent() == game.drag_layer)
	assert(card.global_position.is_equal_approx(home))
	for index in 60:
		var head := snake.cells[0]
		snake.step()
		snake._advance_slide(1.0)
		assert(head.distance_to(snake.cells[0]) <= 1.0)
		var occupied: Array[Vector2i] = []
		for cell in snake.cells:
			assert(not occupied.has(cell))
			assert(cell.x >= 0 and cell.x < snake.columns and cell.y >= 0 and cell.y < snake.rows)
			occupied.append(cell)
	# Full difficulty must still leave free cells for a hand and respawns.
	game.pile_count = 25
	game.piles.clear()
	for index in 25:
		var pile := preload("res://resources/scenes/gameplay/Pile.tscn").instantiate() as MemoryPile
		game.piles_board.add_child(pile)
		pile.setup(index, 5)
		game.piles.append(pile)
	snake.start(game, game.run_rng.get_stream(&"movement"))
	snake.place_hand()
	assert(snake.cells.size() == 25 and snake.card_cells.size() == 4)
	assert(snake._free_cells().size() >= 1)
	await game.special_rule_manager.end_round()
	assert(not snake.active and snake.card_cells.is_empty())
	game.queue_free()
	await process_frame
	print("Snake rule tests passed: grid, chase, eating, cap, completed tail, held cards, 25 piles and cleanup.")
	quit()

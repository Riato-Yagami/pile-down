extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(45).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	game.start_game(false, null, false, "SNAKE-SLIDE", {}, [&"snake"], {"pile_count": 4, "hand_size": 1, "start_value": 5})
	while game.input_locked or game.hand_manager.current_cards.is_empty():
		await process_frame
	var snake := game.snake_rule_controller
	assert(snake.meal_heal_chance == 0.5)
	snake.meal_heal_chance = 1.0
	snake.set_process(false)
	game.timer_manager.stop_countdown()
	game.hand_manager.finish_all_card_entrances()
	var card: PlayingCard = game.hand_manager.current_cards[0]
	snake.cells.assign([Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)])
	snake._place_segments()
	snake.card_cells.clear()
	snake.card_cells[card] = Vector2i(2, 2)
	card.global_position = snake._global_position(Vector2i(2, 2)) + Vector2(80, -70)
	card.dragging = true
	game.selected_card = card
	var head := snake.segments[0]
	var initial := head.global_position
	snake.step()
	assert(snake.cells[0] == Vector2i(1, 2))
	assert(head.global_position == initial and snake.sliding)
	assert(not snake.cells.has(Vector2i(2, 3)))
	assert(not snake._free_cells().has(Vector2i(2, 3)), "The departing tail square is still occupied visually")
	snake._advance_slide(snake._slide_duration * 0.5)
	assert(head.global_position.distance_to(initial) > 0)
	for free_cell in snake._free_cells():
		var spawn_rect: Rect2 = game.get_global_transform() * Rect2(snake._position(free_cell), card.size)
		for segment in snake.segments:
			assert(not spawn_rect.intersects(segment.get_global_rect()))
	assert(head.global_position.distance_to(snake._global_position(snake.cells[0])) > 0)
	snake._advance_slide(snake._slide_duration * 0.5)
	assert(not snake.sliding)
	assert(head.global_position.is_equal_approx(snake._global_position(snake.cells[0])))
	snake.step()
	snake._advance_slide(1)
	assert(snake.cells[0] == Vector2i(2, 2))
	assert(snake.card_cells[card] == Vector2i(2, 2))
	# With the only tile held, reach its former square then circle it.
	var visited: Array[Vector2i] = []
	for index in 16:
		var occupied := snake.cells.duplicate()
		snake.step()
		assert(not occupied.has(snake.cells[0]))
		snake._advance_slide(1)
		assert(snake._patrol_center == Vector2i(2, 2))
		if not visited.has(snake.cells[0]):
			visited.append(snake.cells[0])
	assert(visited.size() >= 6)
	assert(not visited.has(Vector2i(2, 2)))
	# The square currently occupied by the tail remains forbidden.
	snake.cells.assign([Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2), Vector2i(0, 1)])
	snake._place_segments()
	snake._patrol_center = Vector2i(-1, -1)
	snake.card_cells[card] = Vector2i(0, 0)
	assert(not snake._allowed(Vector2i(0, 1)))
	assert(snake._next_cell() == Vector2i(1, 0))
	# Loose tiles outside a pile hitbox can still feed the head. Any
	# actual pile drop must reach the normal placement/error handler.
	card.card_value = head.expected_value()
	assert(not snake.try_release_card(card, head))
	card.card_value = 0
	var tail: MemoryPile = snake.segments.back()
	tail.current_value = 3
	var original_z := int(snake._original_z[head])
	card.global_position = head.global_position
	var meal_cell := snake.cells[0]
	assert(not snake.try_release_card(card, head))
	assert(snake.try_release_card(card, null))
	assert(game.selected_card == null and not card.dragging)
	assert(snake.card_cells[card] != meal_cell)
	assert(tail.current_value == 3)
	await create_timer(0.8).timeout
	assert(tail.current_value == 4)
	assert(head.z_index > card.z_index)
	# A released tile on the body remains there for the head to approach.
	card.dragging = true
	game.selected_card = card
	card.global_position = snake.segments[1].global_position
	assert(snake.try_release_card(card, null))
	assert(snake.card_cells[card] == snake.cells[1])
	assert(tail.current_value == 4)
	snake.step()
	assert(snake.sliding)
	snake.stop()
	assert(not snake.sliding and head.z_index == original_z)
	game.queue_free()
	await process_frame
	print("Snake sliding tests passed: interpolation, held targets, circling, tail collision, released meals and cleanup.")
	quit()

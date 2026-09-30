extends SceneTree

var round_finished := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.start_game(false, null, false, "DISCARD-LIFECYCLE", {}, [], {
		"pile_count": 2, "hand_size": 3, "start_value": 5, "turn_time": 20.0,
	})
	while game.input_locked:
		await process_frame
	await create_timer(0.4).timeout
	game.timer_manager.stop_countdown()
	game._click_to_place_enabled = true
	var selected := game.hand_manager.current_cards[0]
	game.hand_manager.track_discarding_card(selected)
	assert(DiscardPlayController.claim_on_press(game, selected))
	CardClickController.select_on_tap(game, selected)
	game._start_discard_current_hand(true, true)
	var incoming := preload("res://resources/scenes/gameplay/Card.tscn").instantiate() as PlayingCard
	game.drag_layer.add_child(incoming)
	incoming.global_position = selected.global_position + Vector2(150, 0)
	game.hand_manager.current_cards.append(incoming)
	await process_frame
	assert(game.selected_card == selected, "A click selection survives until another tile covers it")
	incoming.global_position = selected.global_position
	await process_frame
	await process_frame
	assert(game.selected_card == null and not selected.selectable,
		"An incoming tile must discard the old click selection")
	assert(game.mistakes_left == game.maximum_mistakes)
	await create_timer(0.4).timeout
	assert(not is_instance_valid(selected))
	# A held drag is never expired by overlap with the incoming hand.
	selected = incoming
	game.hand_manager.track_discarding_card(selected)
	assert(DiscardPlayController.claim_on_press(game, selected))
	selected.drag_target = selected.get_global_rect().get_center()
	game._on_card_drag_started(selected)
	assert(selected.dragging)
	var joker := preload("res://resources/scenes/gameplay/Card.tscn").instantiate() as PlayingCard
	game.drag_layer.add_child(joker)
	joker.set_joker(true)
	joker.global_position = selected.global_position
	game.hand_manager.current_cards.append(joker)
	await process_frame
	assert(game.selected_card == selected and selected.dragging)
	# End of round must animate both the reserved drag and an unused joker.
	game.round_number = 1
	for pile in game.piles:
		pile.current_value = 0
		pile.completed = true
	var before := joker.global_position
	_finish_round(game)
	assert(is_instance_valid(selected) and is_instance_valid(joker))
	assert(not selected.selectable and not joker.selectable)
	await create_timer(0.1).timeout
	assert(is_instance_valid(joker) and joker.global_position.y > before.y)
	assert(joker.modulate.a < 1.0, "Round cleanup must animate before freeing the hand")
	while not round_finished:
		await process_frame
	assert(not is_instance_valid(selected) and not is_instance_valid(joker))
	assert(game.hand_manager.current_cards.is_empty() and game.hand_manager.discarding_cards.is_empty())
	game.queue_free()
	await process_frame
	print("Covered click selections and end-of-round discard animations passed.")
	quit()


func _finish_round(game: GameManager) -> void:
	await game._finish_round()
	round_finished = true

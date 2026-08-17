extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_until_unlocked(game)
	if game.round_modifiers.wandering_hand_cards:
		game.round_modifiers.wandering_hand_cards = false
		for generated_card in game.hand_manager.current_cards:
			generated_card.disable_wandering()
			generated_card.free_range_card = false
			generated_card.reparent(game.hand_container)
		game.hand_container.queue_sort()
		await process_frame
		await process_frame

	var original_hand := game.hand_manager.current_cards.duplicate()
	var card := original_hand[0] as PlayingCard
	var pile := game.piles[0] as MemoryPile
	var original_mistakes := game.mistakes_left
	card.hover_reveal_enabled = true
	card.face_up = true
	game._on_card_drag_started(card)
	card.finish_drag()
	await game._handle_mistake(pile)

	assert(game.mistakes_left == original_mistakes - 1)
	assert(game.hand_manager.current_cards == original_hand)
	assert(card.get_parent() == game.hand_container)
	assert(card.scale.is_equal_approx(Vector2.ONE))
	assert(not card.face_up)
	assert(card.selectable)
	assert(not game.input_locked)
	assert(game.timer_manager.running)

	await create_timer(1.0).timeout

	var timed_out_card := game.hand_manager.current_cards[0] as PlayingCard
	var mistakes_before_timeout := game.mistakes_left
	game._on_card_drag_started(timed_out_card)
	await game._on_time_expired()
	assert(game.mistakes_left == mistakes_before_timeout - 1)
	assert(timed_out_card.get_parent() == game.hand_container)
	assert(not timed_out_card.dragging)
	assert(timed_out_card.selectable)
	assert(not game.input_locked)

	assert(game.mistakes_left == 1)
	game._handle_mistake(game.piles[0])
	var reveal_deadline := Time.get_ticks_msec() + 2000
	while not _all_visible_piles_revealed(game) and Time.get_ticks_msec() < reveal_deadline:
		assert(not game.overlay.visible)
		await process_frame
	assert(game.mistakes_left == 0)
	assert(not game.overlay.visible)
	assert(game.music_manager.low_pass_enabled)
	assert(_all_visible_piles_revealed(game))
	var overlay_deadline := Time.get_ticks_msec() + 2000
	while not game.overlay.visible and Time.get_ticks_msec() < overlay_deadline:
		await process_frame
	assert(game.overlay.visible)
	assert(game.overlay_mode == "restart")
	assert(game.input_locked)

	print("Mistake retry integration test passed.")
	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)


func _all_visible_piles_revealed(game: GameManager) -> bool:
	for pile in game.piles:
		if pile.visible and not pile.completed and not pile.face_up:
			return false
	return true

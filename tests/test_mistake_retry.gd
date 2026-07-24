extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_until_unlocked(game)

	var original_hand := game.hand_manager.current_cards.duplicate()
	var card := original_hand[0] as PlayingCard
	var pile := game.piles[0] as MemoryPile
	var original_mistakes := game.mistakes_left
	game._on_card_drag_started(card)
	card.finish_drag()
	game._handle_mistake(pile)
	await create_timer(0.2).timeout

	assert(game.mistakes_left == original_mistakes - 1)
	assert(game.hand_manager.current_cards == original_hand)
	assert(card.get_parent() == game.hand_container)
	assert(card.selectable)
	assert(not game.input_locked)
	assert(game.timer_manager.running)

	await create_timer(1.0).timeout

	var timed_out_card := game.hand_manager.current_cards[0] as PlayingCard
	var mistakes_before_timeout := game.mistakes_left
	game._on_card_drag_started(timed_out_card)
	game._on_time_expired()
	await create_timer(0.2).timeout
	assert(game.mistakes_left == mistakes_before_timeout - 1)
	assert(timed_out_card.get_parent() == game.hand_container)
	assert(not timed_out_card.dragging)
	assert(timed_out_card.selectable)
	assert(not game.input_locked)

	print("Mistake retry integration test passed.")
	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

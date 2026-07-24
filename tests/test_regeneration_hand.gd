extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_until_unlocked(game)

	var previous_hand := game.hand_manager.current_cards.duplicate()
	for card in previous_hand:
		card.card_value = 99
	game._on_pile_regenerated(game.piles[0], 1)
	await process_frame
	assert(game.input_locked)
	await _wait_until_unlocked(game)

	assert(game.hand_manager.current_cards != previous_hand)
	var has_playable_card := false
	for card in game.hand_manager.current_cards:
		for pile in game.piles:
			if pile.can_accept(card.card_value):
				has_playable_card = true
				break
		if has_playable_card:
			break
	assert(has_playable_card)

	await create_timer(0.5).timeout
	print("Regeneration hand integration test passed.")
	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

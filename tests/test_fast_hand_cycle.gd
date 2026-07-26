extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_until_unlocked(game)
	# This test measures the normal refill path independently from any rule
	# forced through DebugSettings.
	game.round_modifiers.musical_stacks_enabled = false

	var playable_card: PlayingCard
	var target_pile: MemoryPile
	for card in game.hand_manager.current_cards:
		for pile in game.piles:
			if pile.can_accept(card.card_value):
				playable_card = card
				target_pile = pile
				break
		if playable_card != null:
			break
	assert(playable_card != null)
	assert(target_pile != null)

	var previous_hand := game.hand_manager.current_cards.duplicate()
	game._on_card_drag_started(playable_card)
	var placement_started := Time.get_ticks_msec()
	game._place_selected_card(target_pile)
	var replacement_deadline := placement_started + 2000
	while (
		(
			game.hand_manager.current_cards.is_empty()
			or game.hand_manager.current_cards == previous_hand
		)
		and Time.get_ticks_msec() < replacement_deadline
	):
		await process_frame
	var replacement_appearance_delay := Time.get_ticks_msec() - placement_started
	# Automatic bonus chains and pile completion are fully resolved before the
	# replacement hand is allowed to appear.
	assert(replacement_appearance_delay < 1600)
	assert(game.input_locked)
	assert(not game.hand_manager.current_cards.is_empty())
	assert(game.hand_manager.current_cards != previous_hand)
	await process_frame

	await _wait_until_unlocked(game)
	var interaction_delay := Time.get_ticks_msec() - placement_started

	assert(interaction_delay < 1800)
	assert(not target_pile.face_up or target_pile.completed)
	for card in game.hand_manager.current_cards:
		assert(card.modulate.a >= 1.0)
		assert(card.selectable)
		assert(not card._entrance_animation_running)
	assert(not game.hand_manager.current_cards.is_empty())

	await create_timer(1.0).timeout
	var previous_x := -INF
	for card in game.hand_manager.current_cards:
		assert(card.get_parent() == game.hand_container)
		assert(card.global_position.x > previous_x)
		assert(card._entrance_home_positions.is_empty())
		previous_x = card.global_position.x
	print("Fast hand cycle integration test passed.")
	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

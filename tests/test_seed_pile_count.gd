extends "res://tests/test_seed_replay.gd"


func _run() -> void:
	create_timer(80).timeout.connect(func(): quit(1))
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	game.max_discovered_pile_count = DifficultySettings.MAX_PILES
	game.endless_unlocked = true
	assert(game._sanitized_seed_difficulty({"pile_count": 25})["pile_count"] == 25)
	assert(game._sanitized_seed_difficulty({"pile_count": 999})["pile_count"] == DifficultySettings.MAX_PILES)
	assert(game._sanitized_seed_difficulty({"pile_count": 0})["pile_count"] == 0)
	for count in [5, 12, 25]:
		game._open_challenge_selection()
		await process_frame
		var selection := game.challenge_selection
		assert(selection._seed_piles.get_meta("max_value") == DifficultySettings.MAX_PILES)
		for step in count:
			selection._step_value_selector(selection._seed_piles, 1)
		assert(selection._seed_difficulty_overrides()["pile_count"] == count)
		selection._seed_input.text = "MANY-PILES-%d" % count
		selection._seed_endless.set_pressed_no_signal(count == 25)
		selection._play_seed()
		await _wait_for_hand(game)
		assert(game.pile_count == count and game.piles.size() == count)
		assert(game.run_seed_difficulty["pile_count"] == count)
		assert(game.hand_manager.current_cards.any(func(card: PlayingCard):
			return card.is_joker or game._playable_values().has(card.card_value)))
		var hand := _hand_values(game)
		await game._restart_current_mode()
		await _wait_for_hand(game)
		assert(game.pile_count == count and game.piles.size() == count)
		assert(game.run_seed_difficulty["pile_count"] == count)
		assert(_hand_values(game) == hand)
	game.queue_free()
	await process_frame
	print("Seed pile counts passed: menu launch and replay with 5, 12 and 25 piles, caps and AUTO.")
	quit()

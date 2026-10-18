extends "res://tests/test_seed_replay.gd"


func _run() -> void:
	create_timer(75.0).timeout.connect(func(): quit(1))
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.splash.visible = false
	game._open_challenge_selection()
	await process_frame
	var selection := game.challenge_selection
	for selector in [selection._seed_piles, selection._seed_hand, selection._seed_value, selection._seed_timer]:
		assert(selector.get_meta("value") == 0)
		selection._step_value_selector(selector, 1)
		assert(selector.get_meta("value") > 0)
		selection._step_value_selector(selector, -1)
		assert(selector.get_meta("value") == 0)
	selection._step_value_selector(selection._seed_timer, 1)
	assert(selection._seed_timer.get_meta("value") >= game.Difficulty.MIN_TURN_TIME)
	selection.visible = false

	game.best_rounds_left = 1
	for endless in [false, true]:
		for custom in [0, 1, 2]:
			var initial := {"start_round": 7}
			if custom == 1:
				initial.merge({"pile_count": 3, "hand_size": 2, "start_value": 5, "turn_time": 4.0})
			elif custom == 2:
				initial.merge({"pile_count": 0, "hand_size": 2, "start_value": 0, "turn_time": 0})
			var settings := game._sanitized_seed_difficulty(initial)
			var expected := DifficultyProgression.new()
			var streams := RunRNG.new()
			streams.initialize(RunRNG.seed_string_to_int("LATE-PROGRESSION"))
			var difficulty_rng := streams.get_stream(&"difficulty")
			# Replay each normal transition, including skipped upgrades and tier relief.
			for round_index in range(2, 8):
				expected.advance(difficulty_rng, round_index)
			if custom == 1:
				expected.pile_count = settings["pile_count"]
				expected.hand_size = settings["hand_size"]
				expected.start_value = settings["start_value"]
				expected.turn_time = settings["turn_time"]
			elif custom == 2:
				expected.hand_size = 2
			game.start_game(endless, null, false, "LATE-PROGRESSION", {}, [], initial)
			await _wait_for_hand(game)
			assert(game.run_start_round == 7 and game._progression_round() == 7)
			assert(game.pile_count == expected.pile_count)
			assert(game.hand_size == expected.hand_size)
			assert(game.start_value == expected.start_value)
			assert(game.turn_time == expected.turn_time)
			assert(game.difficulty_droughts == expected.droughts)
			assert(game.tier_reliefs_applied == expected.tier_reliefs_applied)
			assert(game.rng.state == difficulty_rng.state)
			var hand := _hand_values(game)
			await game._restart_current_mode()
			await _wait_for_hand(game)
			assert(game.pile_count == expected.pile_count and game.start_value == expected.start_value)
			assert(_hand_values(game) == hand)
	game.queue_free()
	await process_frame
	print("Seeded late-start progression tests passed.")
	quit()

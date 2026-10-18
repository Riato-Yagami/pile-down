extends "res://tests/analyze_hand_balance.gd"


func _run() -> void:
	create_timer(60.0).timeout.connect(func(): quit(1))
	root.add_child(sampler)
	root.add_child(container)
	var piles := _make_piles(4)
	for pile in piles:
		pile.current_value = 6
	piles[3].current_value = 5
	var before: Array[int] = [6, 6, 6, 5]
	var weights := PileDrawBias.build_weights(piles, 7, false, 0.3)
	assert(weights[4] > weights[5], "Prefer some separation on a nearly aligned board")
	for index in piles.size():
		assert(piles[index].current_value == before[index] and piles[index].history.is_empty())
	piles[3].current_value = 3
	weights = PileDrawBias.build_weights(piles, 7, false, 0.3)
	assert(weights[5] > weights[2], "Prefer another pile when one has a substantial lead")
	# Mirror the board: Pile Up must apply the exact same preference.
	for pile in piles:
		pile.current_value = 7 - pile.current_value
		pile.stack_direction = RoundModifiers.StackDirection.UP
	var mirrored := PileDrawBias.build_weights(piles, 7, true, 0.3)
	for value: int in weights:
		assert(is_equal_approx(weights[value], mirrored[7 - value]))
	for pile in piles:
		pile.current_value = 3
		pile.stack_direction = RoundModifiers.StackDirection.DOWN
	piles[3].current_value = 2
	weights = PileDrawBias.build_weights(piles, 3, false, 0.3)
	assert(weights.is_empty(), "Very short rounds keep the original policy")
	for pile in piles:
		pile.current_value = 4
	piles[3].current_value = 3
	weights = PileDrawBias.build_weights(piles, 4, false, 0.3)
	assert(weights[2] > weights[3], "The smaller target still discourages alignment")
	for pile in piles:
		pile.current_value = 9
	piles[3].current_value = 1
	weights = PileDrawBias.build_weights(piles, 9, false, 0.3)
	assert(weights[0] >= 0.05 and weights[0] < weights[8])
	assert(PileDrawBias.build_weights(piles, 9, false, 0.0).is_empty())
	for index in 3:
		piles[index].current_value = 0
		piles[index].completed = true
	assert(PileDrawBias.build_weights(piles, 9, false, 0.3).is_empty())
	for pile in piles:
		pile.current_value = 6
		pile.completed = false
	assert(PileDrawBias.build_weights(piles, 7, false, 0.3).is_empty())
	piles[3].current_value = 5
	# Weighted draws use only the run RNG and replay identically on the same board.
	var replay_values: Array[int] = []
	var replay_state := 0
	for attempt in 2:
		sampler.rng.seed = 1026
		sampler.sampled.clear()
		sampler.generate_hand(container, 4, 7, [5, 5, 5, 4], false,
			false, false, false, true, false, null, 0.0, false,
			0.0, 0, 0, 0, piles, true, false, piles[3], 0.4, 0.6, 0.3)
		if attempt == 0:
			replay_values.assign(sampler.sampled)
			replay_state = sampler.rng.state
		else:
			assert(sampler.sampled == replay_values and sampler.rng.state == replay_state)
	# Reload Required, including its tutorial, keeps its original draw sequence.
	for forced in [false, true]:
		var reference: Array[int] = []
		var reference_state := 0
		for strength in [0.0, 50.0]:
			sampler.rng.seed = 42
			sampler.sampled.clear()
			sampler.generate_hand(container, 4, 7, [5, 5, 5, 4], false,
				false, false, false, true, false, null, 0.0, false,
				0.0, 0, 0, 0, piles, false, forced, piles[3], 0.4, 0.6, strength)
			if strength == 0.0:
				reference.assign(sampler.sampled)
				reference_state = sampler.rng.state
			else:
				assert(sampler.sampled == reference and sampler.rng.state == reference_state)
			if forced:
				assert(sampler.sampled.all(func(value: int): return value not in [4, 5]))
	# Lucky Hand III overrides the contextual bias even when it is very strong.
	sampler.sampled.clear()
	sampler.generate_hand(container, 4, 7, [5, 5, 5, 4], false,
		false, false, false, true, false, null, 0.0, false,
		1.0, 3, 0, 0, piles, true, false, piles[3], 0.4, 0.6, 50.0)
	assert(sampler.sampled.slice(0, 3) == [4, 5, 5])
	# Full rounds with the real policy and a single available card stay playable.
	var config := {"id": "test", "chain": 1.0, "align": 1.0, "production_strength": 50.0}
	var result := _simulate(config, 1, 4, "serial", 0)
	assert(result.rounds == ROUNDS)
	for pile in piles:
		pile.free()
	sampler.queue_free()
	container.queue_free()
	await process_frame
	print("Contextual pile draw policy tests passed.")
	quit()

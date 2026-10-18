extends SceneTree

var manager := HandManager.new()
var container := Control.new()
var last_pile := MemoryPile.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.add_child(manager)
	root.add_child(container)
	manager.card_scene = preload("res://resources/scenes/gameplay/Card.tscn")
	last_pile.current_value = 2
	var ordinary := RandomNumberGenerator.new()
	ordinary.seed = 42
	manager.rng.seed = 42
	for sample in 1000:
		assert(manager._draw_with_suppression([0, 1, 2, 3], 1, 0.0) == ordinary.randi_range(0, 3))
	assert(manager.rng.state == ordinary.state, "Zero suppression preserves the RNG sequence")
	ordinary.seed = 42
	manager.rng.seed = 42
	for sample in 1000:
		assert(manager.draw_spaced_value([0, 1, 2, 3], 1, 0.0, 2, 0.0) == ordinary.randi_range(0, 3))
	assert(manager.rng.state == ordinary.state)
	var counts: Array[int] = []
	for suppression in [0.0, 0.5, 1.0]:
		manager.rng.seed = 42
		var count := 0
		for sample in 10000:
			if manager._draw_with_suppression([1, 2, 3], 1, suppression) == 1:
				count += 1
		counts.append(count)
	assert(counts[0] > counts[1] and counts[1] > 0 and counts[2] == 0)
	manager.rng.seed = 42
	var spaced_counts: Array[int] = [0, 0, 0]
	for sample in 20000:
		spaced_counts[manager.draw_spaced_value([0, 1, 2], 0, 0.4, 1, 0.6)] += 1
	assert(spaced_counts[2] > spaced_counts[0] and spaced_counts[0] > spaced_counts[1])
	for sample in 100:
		assert(manager.draw_spaced_value([0, 1, 2], 0, 1.0, 1, 1.0) == 2)
		assert(manager.draw_spaced_value([1, 1], 0, 1.0, 1, 1.0) == 1)
		assert(manager.draw_spaced_value([0, 1], 0, 1.0, 1, 1.0) in [0, 1])
	# Disabling the second bias must not switch the first to a different sampler.
	manager.rng.seed = 81
	var zero_repeat := 0
	for sample in 20000:
		zero_repeat += int(manager.draw_spaced_value([0, 1, 1, 1], 0, 0.4, 1, 0.0) == 0)
	assert(absf(float(zero_repeat) / 20000.0 - 1.0 / 6.0) < 0.015)
	manager.rng.seed = 81
	var near_zero_repeat := 0
	for sample in 20000:
		near_zero_repeat += int(manager.draw_spaced_value([0, 1, 1, 1], 0, 0.4, 1, 0.000001) == 0)
	assert(absi(zero_repeat - near_zero_repeat) <= 1)
	for sample in 40:
		_draw([1, 5])
		assert(manager.current_cards.any(func(card: PlayingCard) -> bool: return card.card_value == 5))
		assert(manager.current_cards.all(func(card: PlayingCard) -> bool: return card.card_value != 1))
		await process_frame
	_draw([1, 1])
	assert(manager.current_cards.any(func(card: PlayingCard) -> bool: return card.card_value == 1))
	await process_frame
	_draw([1, 5], true, false, 1.0)
	assert(manager.current_cards[0].card_value == 1, "Lucky Hand bypasses suppression")
	await process_frame
	_draw([1, 5], false, true, 1.0)
	assert(manager.current_cards.all(func(card: PlayingCard) -> bool: return card.card_value not in [1, 5]))
	await process_frame
	var found_unplayable := false
	for sample in 50:
		_draw([1, 5], false)
		if manager.current_cards.all(func(card: PlayingCard) -> bool: return card.card_value not in [1, 5]):
			found_unplayable = true
		await process_frame
	assert(found_unplayable, "Reload Required must still draw unplayable hands")
	last_pile.stack_direction = RoundModifiers.StackDirection.UP
	last_pile.current_value = 1
	_draw([2, 5], true, false, 0.0, true)
	assert(manager.current_cards.all(func(card: PlayingCard) -> bool: return card.card_value != 2 and card.card_value >= 1))
	last_pile.free()
	manager.queue_free()
	container.queue_free()
	await process_frame
	print("Last pile suppression tests passed.")
	quit()


func _draw(playable: Array[int], guaranteed := true, forced_reload := false, lucky := 0.0, up := false) -> void:
	manager.generate_hand(
		container, 4, 7, playable, up, false, false, false, true, false,
		null, 0.0, false, lucky, 1, 0, 0, [], guaranteed, forced_reload,
		last_pile, 1.0, 0.6
	)

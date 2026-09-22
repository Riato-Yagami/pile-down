extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for joker_index in [0, 2]:
		var center := CenterContainer.new()
		center.size = Vector2(240, 80)
		root.add_child(center)
		var hand := HBoxContainer.new()
		hand.add_theme_constant_override("separation", 5)
		center.add_child(hand)
		var exits := Control.new()
		root.add_child(exits)
		var manager := HandManager.new()
		manager.card_scene = preload("res://resources/scenes/gameplay/Card.tscn")
		root.add_child(manager)
		manager.generate_hand(hand, 4, 5, [2], false, false, false, false)
		await process_frame
		await process_frame
		var joker := manager.current_cards[joker_index]
		joker.set_joker(true)
		var original := joker.visual_root.global_position
		var leftmost := manager.current_cards[0].visual_root.global_position
		manager.discard_hand(hand, exits)
		for frame in 8:
			await process_frame
			assert(joker.visual_root.global_position.is_equal_approx(original),
				"Retained joker moved while the old hand was being discarded")
		await create_timer(0.5).timeout
		assert(joker.visual_root.global_position.is_equal_approx(original))
		manager.generate_hand(hand, 4, 5, [2], false, false, false, true, true, true)
		var previous_x := original.x
		var deadline := Time.get_ticks_msec() + 800
		while Time.get_ticks_msec() < deadline:
			await process_frame
			var current := joker.visual_root.global_position
			assert(current.x <= previous_x + 0.01, "Retained joker moved back to the right")
			assert(current.x >= leftmost.x - 0.01, "Retained joker overshot its slot")
			if joker_index == 0:
				assert(current.is_equal_approx(original), "Leftmost joker should stay still")
			previous_x = current.x
		assert(joker.visual_root.global_position.is_equal_approx(leftmost))
		assert(not joker.visual_root.is_set_as_top_level())
		assert(joker.selectable)
		assert(joker.hand_return_position().is_equal_approx(joker.global_position))
		manager.queue_free()
		center.queue_free()
		exits.queue_free()
		await process_frame
	await _test_joker_removed_on_death()
	await _test_joker_removed_on_quit()
	print("Retained joker layout, death and quit cleanup tests passed.")
	quit()


func _test_joker_removed_on_death() -> void:
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)
	var joker := game.hand_manager.current_cards[0]
	joker.set_joker(true)
	await game._handle_mistake(null, true, true, true)
	await create_timer(0.6).timeout
	assert(game.overlay.visible)
	assert(game.mistakes_left == 0)
	assert(not is_instance_valid(joker), "Unused joker survived game over")
	assert(game.hand_manager.current_cards.is_empty())
	game.queue_free()
	await process_frame


func _test_joker_removed_on_quit() -> void:
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	for hold_position in [false, true]:
		game.start_game()
		var deadline := Time.get_ticks_msec() + 10000
		while game.input_locked and Time.get_ticks_msec() < deadline:
			await process_frame
		assert(not game.input_locked)
		var old_cards := game.hand_manager.current_cards.duplicate()
		var joker := game.hand_manager.current_cards[0]
		joker.set_joker(true)
		if hold_position:
			joker.hold_hand_position()
		await game._return_to_menu()
		await process_frame
		assert(game.splash.visible)
		assert(game.hand_manager.current_cards.is_empty(), "Quit preserved the old hand")
		for card in old_cards:
			assert(not is_instance_valid(card), "A card from the previous run survived quit")
	game.start_game()
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)
	assert(not game.hand_manager.current_cards.is_empty())
	game.queue_free()
	await process_frame

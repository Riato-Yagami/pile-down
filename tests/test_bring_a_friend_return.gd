extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_until_unlocked(game)

	var bonus_data: BonusData
	for definition in game.bonus_manager.definitions:
		if definition.id == &"bring_a_friend":
			bonus_data = definition
			break
	assert(bonus_data != null)
	game.bonus_manager._add_or_upgrade(bonus_data)
	game.bonus_manager._add_or_upgrade(bonus_data)

	game.input_locked = true
	game.timer_manager.stop_countdown()
	await game._discard_current_hand()
	game.hand_size = 3
	game._hand_cycle_generation += 1
	await game._begin_turn(false, false)
	await _wait_until_unlocked(game)
	await process_frame

	var cards := game.hand_manager.current_cards.duplicate()
	assert(cards.size() == 3)
	var original_positions: Dictionary = {}
	for card in cards:
		original_positions[card] = card.global_position

	for attempt in 4:
		var main_card := cards[1] as PlayingCard
		game._on_card_drag_started(main_card)
		assert(game.drag_companions.size() == 2)
		await game._on_card_drag_released(main_card, Vector2(8.0, 180.0))
		await process_frame
		for index in cards.size():
			var card := cards[index] as PlayingCard
			assert(card.get_parent() == game.hand_container)
			assert(card.get_index() == index)
			assert(
				card.global_position.is_equal_approx(
					original_positions[card] as Vector2
				)
			)
		for child in game.hand_container.get_children():
			assert(not child.has_meta(&"hand_drag_placeholder"))

	print("Bring a Friend return regression test passed.")
	game.queue_free()
	await process_frame
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

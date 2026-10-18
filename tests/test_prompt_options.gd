extends "res://tests/test_click_to_place.gd"


func _run() -> void:
	create_timer(45.0).timeout.connect(func(): quit(1))
	game = preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game._click_to_place_enabled = true
	game._drag_and_drop_enabled = true
	await _new_run()
	game.round_modifiers.sticky_fingers_enabled = true
	var card := game.hand_manager.current_cards[0]
	var other := game.hand_manager.current_cards[1]
	card.card_value = 4
	await _tap(card.get_global_rect().get_center(), true)
	assert(card.sticky_committed and card.selection_outline.visible)
	assert(card.selection_outline.modulate.g > card.selection_outline.modulate.r)
	await _tap(other.get_global_rect().get_center(), true)
	assert(game.selected_card == card and not other._selected)
	await _tap(other.get_global_rect().get_center())
	assert(game.selected_card == card and not other._selected)
	await _tap(Vector2(8, 180))
	assert(game.selected_card == card)
	await _tap(game.piles[0].get_global_rect().get_center(), true)
	await create_timer(0.7).timeout
	assert(game.piles[0].current_value == 4)

	await _new_run()
	game.round_modifiers.sticky_fingers_enabled = true
	card = game.hand_manager.current_cards[0]
	card.card_value = 4
	var point := card.get_global_rect().get_center()
	_touch_button(point, true)
	await create_timer(0.15).timeout
	_touch_motion(point + Vector2(20, -20))
	assert(card.dragging and card.selection_outline.visible)
	var placeholder := game.drag_placeholder
	_touch_button(Vector2(50, 170), false)
	assert(not card.dragging and card._selected and card.sticky_committed)
	var resting := card.global_position
	await process_frame
	assert(card.global_position.is_equal_approx(resting))
	point = card.get_global_rect().get_center()
	_touch_button(point, true)
	await create_timer(0.15).timeout
	_touch_motion(point + Vector2(20, -20))
	assert(card.dragging and game.drag_placeholder == placeholder)
	_touch_button(game.piles[0].get_global_rect().get_center(), false)
	await create_timer(0.7).timeout
	assert(game.piles[0].current_value == 4)

	card = game.hand_manager.current_cards[0]
	card.sticky_committed = true
	card.set_selected_visual(false)
	card._animate_pose(Vector2(1.06, 1.06), -2.0)
	for frame in 12:
		await process_frame
		assert(is_equal_approx(card.selection_outline.position.y, card.face_sprite.position.y - 2.0))
	card.reset_hand_pose()
	assert(is_equal_approx(card.selection_outline.position.y, -2.0))

	for touch in [false, true]:
		await _new_run()
		game.round_modifiers.sticky_fingers_enabled = true
		card = game.hand_manager.current_cards[0]
		other = game.hand_manager.current_cards[1]
		card.card_value = 0
		await _tap(card.get_global_rect().get_center(), touch)
		assert(card.sticky_committed and card._selected)
		await _tap(game.piles[0].get_global_rect().get_center(), touch)
		assert(game.selected_card == null and not card.sticky_committed)
		assert(not card._selected and not card.selection_outline.visible)
		await create_timer(0.3).timeout
		await _tap(other.get_global_rect().get_center(), touch)
		assert(game.selected_card == other and other.sticky_committed)

	var original_fixed := game._fixed_background
	game.fixed_background_button.pressed.emit()
	assert(game._fixed_background != original_fixed)
	assert(SaveConfig.load_current().get_value("graphics", "fixed_background") == game._fixed_background)
	game.fixed_background_button.pressed.emit()
	var original_pause := game._pause_between_rounds
	game.pause_between_rounds_button.pressed.emit()
	assert(game._pause_between_rounds != original_pause)
	assert(SaveConfig.load_current().get_value("gameplay", "pause_between_rounds") == game._pause_between_rounds)
	game.pause_between_rounds_button.pressed.emit()

	await _new_run()
	game._pause_between_rounds = true
	game.flawless_since_last_bonus = false
	var previous_round := game.round_number
	for pile in game.piles:
		pile.current_value = 0
		pile.completed = true
	game.RoundFlowControllerScript.finish_round(game)
	while not game.skippable_sequence.waiting_for_continue:
		await process_frame
	assert(game.round_number != previous_round and game.input_locked)
	assert(game.transient_label.visible)
	await create_timer(0.3).timeout
	assert(game.input_locked and game.skippable_sequence.waiting_for_continue)
	game.skippable_sequence.skip_to_end()
	while game.input_locked:
		await process_frame
	game.timer_manager.stop_countdown()
	assert(game.piles.any(func(pile: MemoryPile): return not pile.completed))
	game._pause_between_rounds = original_pause

	var label := game.transient_label
	var animation := game.DifficultyAnnouncementScript.animate(label, PackedStringArray(["TEST"]), 0.0, 0.0, true)
	await animation.finished
	assert(label.visible and label.modulate.a == 1.0 and label.get_child_count() > 0)
	game.skippable_sequence.begin_wait()
	await create_timer(0.2).timeout
	assert(game.skippable_sequence.waiting_for_continue and label.visible)
	var key := InputEventKey.new()
	key.keycode = KEY_A
	key.pressed = true
	game.skippable_sequence._unhandled_input(key)
	assert(not game.skippable_sequence.waiting_for_continue)
	game.skippable_sequence.finish()
	game.queue_free()
	await process_frame
	print("Prompt options and Sticky Fingers tests passed.")
	quit()

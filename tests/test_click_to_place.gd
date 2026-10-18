extends SceneTree

var game: GameManager


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(90.0).timeout.connect(func(): quit(1))
	game = preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	assert(game._click_to_place_enabled and game._drag_and_drop_enabled)
	# Toggle through all combinations, including attempts to disable the last mode.
	game.click_to_place_button.pressed.emit()
	assert(not game._click_to_place_enabled and game._drag_and_drop_enabled)
	game.drag_and_drop_button.pressed.emit()
	assert(game._click_to_place_enabled and not game._drag_and_drop_enabled)
	var saved := SaveConfig.load_current()
	assert(saved.get_value("accessibility", "click_to_place") == true)
	assert(saved.get_value("accessibility", "drag_and_drop") == false)
	game.click_to_place_button.pressed.emit()
	assert(not game._click_to_place_enabled and game._drag_and_drop_enabled)
	game.click_to_place_button.pressed.emit()
	await _new_run()
	var card := game.hand_manager.current_cards[0]
	var other := game.hand_manager.current_cards[1]
	card.card_value = 4
	await _tap(card.get_global_rect().get_center())
	assert(game.selected_card == card and card.selection_outline.visible)
	assert(not card.dragging and card.get_parent() == game.hand_container)
	await _tap(other.get_global_rect().get_center())
	assert(game.selected_card == other and not card.selection_outline.visible)
	await _tap(card.get_global_rect().get_center())
	await _tap(game.piles[0].get_global_rect().get_center())
	await create_timer(1.0).timeout
	assert(game.piles[0].current_value == 4, "Mouse click must place the selected tile")

	await _new_run()
	game._drag_and_drop_enabled = false
	card = game.hand_manager.current_cards[0]
	card.card_value = 4
	await _tap(card.get_global_rect().get_center(), true)
	assert(game.selected_card == card and card.selection_outline.visible and not card.dragging)
	await _tap(game.piles[0].get_global_rect().get_center(), true)
	await create_timer(1.0).timeout
	assert(game.piles[0].current_value == 4, "Touch placement must work with drag disabled")

	await _new_run()
	card = game.hand_manager.current_cards[0]
	var point := card.get_global_rect().get_center()
	_mouse_button(point, true)
	_motion(point + Vector2(20, -20))
	assert(not card.dragging, "Disabled mouse drag must not start")
	_mouse_button(point + Vector2(20, -20), false)
	assert(game.selected_card == null, "A movement must not be mistaken for a click")
	game._drag_and_drop_enabled = true
	game._click_to_place_enabled = false
	await _tap(point)
	assert(game.selected_card == null and not card.selection_outline.visible)
	_mouse_button(point, true)
	_motion(point + Vector2(20, -20))
	assert(card.dragging and not card.selection_outline.visible)
	_mouse_button(Vector2(-100, -100), false)
	await create_timer(0.5).timeout
	assert(not card.dragging and game.selected_card == null)

	game._click_to_place_enabled = true
	await _new_run()
	card = game.hand_manager.current_cards[0]
	card.card_value = 0
	var lives := game.mistakes_left
	await _tap(card.get_global_rect().get_center())
	await _tap(game.piles[0].get_global_rect().get_center())
	await create_timer(0.6).timeout
	assert(game.mistakes_left == lives - 1 and game.piles[0].current_value == 5)
	assert(game.selected_card == null and not card.selection_outline.visible)

	await _new_run()
	card = game.hand_manager.current_cards[0]
	point = card.get_global_rect().get_center()
	game._drag_and_drop_enabled = false
	_touch_button(point, true)
	await create_timer(0.15).timeout
	_touch_motion(point + Vector2(20, -20))
	assert(not card.dragging, "Disabled touch drag must not start")
	_touch_button(point + Vector2(20, -20), false)
	assert(game.selected_card == null)
	game._drag_and_drop_enabled = true
	_touch_button(point, true)
	await create_timer(0.15).timeout
	_touch_motion(point + Vector2(20, -20))
	assert(card.dragging, "Touch drag must coexist with tap selection")
	_touch_button(Vector2(-100, -100), false)
	await create_timer(0.5).timeout
	assert(not card.dragging and game.selected_card == null)
	_touch_button(point, true)
	var canceled := InputEventScreenTouch.new()
	canceled.position = point
	canceled.canceled = true
	root.push_input(canceled, true)
	assert(game.selected_card == null and not card.selection_outline.visible)

	await _new_run()
	card = game.hand_manager.current_cards[0]
	for blind in [false, true]:
		for hover in [false, true]:
			card.set_selected_visual(false)
			card.round_modifiers.blind_delivery_enabled = blind
			card.hover_reveal_enabled = hover
			card.set_selected_visual(true)
			assert(card.face_up == (hover or not blind))
			await create_timer(card.touch_drag_face_hold + 0.2).timeout
			assert(card.face_up == (not blind), "Selection must honor combined visibility rules")
			card._on_mouse_exited()
			await create_timer(0.2).timeout
			assert(card.face_up == (not blind))

	await _new_run()
	card = game.hand_manager.current_cards[0]
	for touch in [false, true]:
		await _tap(card.get_global_rect().get_center(), touch)
		assert(game.selected_card == card)
		await _tap(Vector2(8, 180), touch)
		assert(game.selected_card == null and not card._selected)
	card.round_modifiers.hot_potatoes_enabled = true
	card.round_modifiers.hot_potato_drag_duration = 0.3
	var card_position := card.global_position
	lives = game.mistakes_left
	CardClickController.select_on_tap(game, card)
	await create_timer(0.1).timeout
	assert(not card.drag_timer.is_stopped() and card.drag_timer_ring.visible)
	await create_timer(0.3).timeout
	assert(game.selected_card == null and not card._selected)
	assert(card.global_position == card_position and game.mistakes_left == lives)
	assert(not card.forced_return_in_progress)
	assert(await _check_mirror_selection())
	game.queue_free()
	await process_frame
	print("Click/touch placement and accessibility options tests passed.")
	quit()


func _check_mirror_selection() -> bool:
	game._click_to_place_enabled = true
	game._drag_and_drop_enabled = false
	for axes in [Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		for touch in [false, true]:
			await _new_run()
			var modifiers := RoundModifiers.new()
			modifiers.mirror_horizontal = axes.x < 0.0
			modifiers.mirror_vertical = axes.y < 0.0
			game.mirror_match_controller.begin_round(game, modifiers)
			await process_frame
			var pile := game.piles[1 if touch else 0]
			var other_pile := game.piles[0 if touch else 1]
			var card := game.hand_manager.current_cards[0]
			card.card_value = pile.expected_value()
			var lives := game.mistakes_left
			# Use the rendered centers so this exercises actual mouse/touch input
			# under each mirror, independently of Control.get_global_rect().
			await _tap(card.get_global_transform() * (card.size * 0.5), touch)
			assert(game.selected_card == card and not card.dragging)
			await _tap(pile.get_global_transform() * (pile.size * 0.5), touch)
			await create_timer(1.0).timeout
			assert(pile.current_value == 4,
				"Select must place on the clicked pile with mirror axes %s (touch=%s)" % [axes, touch])
			assert(other_pile.current_value == 5 and game.mistakes_left == lives)
	return true


func _new_run() -> void:
	await game.cleanup_special_rule_state(false)
	game.start_game(false, null, false, "CLICK-TEST", {}, [], {
		"pile_count": 2, "hand_size": 3, "start_value": 5, "turn_time": 20.0,
	})
	while game.input_locked:
		await process_frame
	game.timer_manager.stop_countdown()
	await create_timer(0.4).timeout


func _tap(point: Vector2, touch := false) -> void:
	for pressed in [true, false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.position = point
			event.pressed = pressed
			root.push_input(event, true)
		else:
			_mouse_button(point, pressed)
		await process_frame


func _mouse_button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event, true)


func _motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true)


func _touch_button(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)


func _touch_motion(point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.position = point
	root.push_input(event, true)

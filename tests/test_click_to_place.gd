extends SceneTree

var game: GameManager


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(60.0).timeout.connect(func(): quit(1))
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
	game.queue_free()
	await process_frame
	print("Click/touch placement and accessibility options tests passed.")
	quit()


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

extends SceneTree

var game: GameManager


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(60.0).timeout.connect(func(): quit(1))
	root.size = Vector2i(1908, 968)
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	game = main.get_node("GameCenter/Game") as GameManager
	DifficultySettings.playable_discard_enabled = true
	DifficultySettings.redraw_after_discard_play = true
	for gesture in ["mouse_drag", "touch_drag", "mouse_click", "touch_click"]:
		print("Discard chain: ", gesture)
		var touch: bool = gesture.begins_with("touch")
		var click: bool = gesture.ends_with("click")
		await game.cleanup_special_rule_state(false)
		game.start_game(false, null, false, "DISCARD-CHAIN", {}, [], {
			"pile_count": 2, "hand_size": 3, "start_value": 5, "turn_time": 20.0,
		})
		while game.input_locked:
			await process_frame
		await create_timer(0.4).timeout
		game.timer_manager.stop_countdown()
		var first := game.hand_manager.current_cards[0]
		var extra := game.hand_manager.current_cards[1]
		first.card_value = 4
		extra.card_value = 3
		await _grab(first, touch, false, click)
		_drop(first, touch)
		await _grab(extra, touch, false, click)
		while game._discard_source_action_active:
			await process_frame
		for value in [2, 1]:
			while game.hand_manager.current_cards.is_empty():
				await process_frame
			var next := game.hand_manager.current_cards[0]
			next.card_value = value
			_drop(extra, touch)
			while is_instance_valid(next) and next.get_parent() != game.drag_layer:
				await process_frame
			assert(is_instance_valid(next) and next.selectable,
				"Redraw after a discard play must leave the outgoing hand selectable")
			assert(DiscardPlayController.can_interact(game, next),
				"Outgoing cards must be grabbable while the redraw owns the input lock")
			# A person presses after seeing the exit, then moves after a short hold.
			var exit_start := next.global_position
			await create_timer(0.09 if value == 2 else 0.14).timeout
			assert(is_instance_valid(next) and next.global_position.y > exit_start.y,
				"The late press must happen during the moving exit")
			assert(next.modulate.a > 0.0 and next.selectable)
			assert(DiscardPlayController.can_interact(game, next))
			await _grab(next, touch, true, click)
			assert(next.discard_claimed)
			extra = next
		_drop(extra, touch)
		while game._discard_play_in_progress or game._discard_source_action_active or game.input_locked:
			await process_frame
		assert(game.piles[0].current_value == 1, "All four placements must resolve in order")
		assert(game.selected_card == null)
		assert(game.mistakes_left == game.maximum_mistakes)
		var playable := false
		for card in game.hand_manager.current_cards:
			playable = playable or card.is_joker or game._playable_values().has(card.card_value)
		assert(playable, "The final redraw must still guarantee a playable card")
		# Cancel a reserved discard without starting a drag or losing a life.
		first = game.hand_manager.current_cards[0]
		extra = game.hand_manager.current_cards[1]
		first.card_value = 4
		game.selected_card = first
		game._place_selected_card(game.piles[1])
		var press_point := extra.get_global_rect().get_center()
		_pointer_button(press_point, touch, true)
		await create_timer(0.4).timeout
		assert(is_instance_valid(extra) and extra.discard_claimed and not extra.dragging)
		if touch:
			var cancel := InputEventScreenTouch.new()
			cancel.position = press_point
			cancel.canceled = true
			root.push_input(cancel, true)
		else:
			_pointer_button(Vector2.ZERO, false, false)
		while game._discard_source_action_active or game._discard_play_in_progress:
			await process_frame
		await create_timer(0.4).timeout
		assert(not is_instance_valid(extra), "A canceled press must not leave a reserved discard behind")
		assert(game.selected_card == null and game.mistakes_left == game.maximum_mistakes)
	main.queue_free()
	await process_frame
	print("Repeated discard redraw tests passed for mouse/touch drags and clicks.")
	quit()


func _grab(card: PlayingCard, touch: bool, delayed_motion := false, click := false) -> void:
	var visible_rect := (card.visual_root.get_global_transform() * Rect2(Vector2.ZERO, card.size)).intersection(root.get_visible_rect())
	assert(visible_rect.has_area(), "The test must press a visible part of the card")
	var point := visible_rect.get_center()
	_pointer_button(point, touch, true)
	await create_timer(0.3 if delayed_motion else 0.13).timeout
	assert(is_instance_valid(card), "A pressed discard must survive until the gesture completes")
	if click:
		_pointer_button(point, touch, false)
		assert(game.selected_card == card and card.selection_outline.visible)
	else:
		_pointer_motion(point + Vector2(0, -12), touch)
		assert(card.dragging, "Pointer movement must grab the outgoing card")
		await create_timer(0.12).timeout
		var grab_point := card.get_global_transform() * card._pointer_offset
		assert(grab_point.distance_to(point + Vector2(0, -12)) < 8.0,
			"The visible grabbed point must follow the pointer without jumping")


func _drop(card: PlayingCard, touch: bool) -> void:
	var point := game.piles[0].get_global_rect().get_center()
	if card.dragging:
		_pointer_motion(point, touch)
	else:
		_pointer_button(point, touch, true)
	_pointer_button(point, touch, false)


func _pointer_button(point: Vector2, touch: bool, pressed: bool) -> void:
	var event: InputEvent
	if touch:
		event = InputEventScreenTouch.new()
	else:
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)


func _pointer_motion(point: Vector2, touch: bool) -> void:
	var event: InputEvent
	if touch:
		event = InputEventScreenDrag.new()
	else:
		event = InputEventMouseMotion.new()
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = point
	root.push_input(event, true)

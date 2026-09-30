extends SceneTree

var game: GameManager


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(60.0).timeout.connect(func(): quit(1))
	game = preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	DifficultySettings.playable_discard_enabled = true
	DifficultySettings.redraw_after_discard_play = false
	await _new_run()
	var extra := await _grab_discard()
	var next_cards := game.hand_manager.current_cards.duplicate()
	var cycle := game._hand_cycle_generation
	await create_timer(0.5).timeout
	assert(is_instance_valid(extra) and extra.dragging)
	assert(game.selected_card == extra, "New hand entrance must not cancel the old drag")
	var time_before := game.timer_manager.time_left
	await game._on_card_drag_released(extra, game.piles[0].get_global_rect().get_center())
	assert(game.piles[0].current_value == 3)
	assert(game._hand_cycle_generation == cycle)
	assert(game.hand_manager.current_cards == next_cards, "Extra play must preserve the next hand")
	assert(game.timer_manager.time_left <= time_before, "Extra play must not reset the clock")
	assert(not game.input_locked)

	await _new_run()
	extra = await _grab_discard(false)
	assert(game._discard_source_action_active)
	assert(DiscardPlayController.can_interact(game, extra))
	cycle = game._hand_cycle_generation
	await game._on_card_drag_released(extra, game.piles[0].get_global_rect().get_center())
	assert(game.piles[0].current_value == 3, "An immediate second drop must resolve after the first: %s" % game.piles[0].current_value)
	assert(game._hand_cycle_generation == cycle)
	assert(not game._discard_source_action_active and not game._discard_play_in_progress)

	await _new_run()
	extra = await _grab_discard()
	next_cards = game.hand_manager.current_cards.duplicate()
	await game._on_card_drag_released(extra, Vector2(-100, -100))
	assert(is_instance_valid(extra) and extra.visible, "Released card must animate before disappearing")
	assert(not extra.selectable and not game.input_locked)
	await create_timer(0.3).timeout
	await process_frame
	assert(not is_instance_valid(extra), "Outside drop must discard the held tile")
	assert(game.hand_manager.current_cards == next_cards)
	assert(game.mistakes_left == game.maximum_mistakes)

	await _new_run()
	extra = await _grab_discard()
	var lives := game.mistakes_left
	# The second pile still expects 4, whereas this discarded card is a 3.
	await game._on_card_drag_released(extra, game.piles[1].get_global_rect().get_center())
	assert(game.mistakes_left == lives - 1)
	assert(game.piles[1].current_value == 5)
	assert(not game.input_locked)

	await _new_run()
	var rejected := game.hand_manager.current_cards[0]
	var following := game.hand_manager.current_cards[1]
	rejected.card_value = 0
	game._on_card_selected(rejected)
	rejected.begin_external_drag(rejected.get_global_rect().get_center())
	game._on_card_drag_released(rejected, game.piles[0].get_global_rect().get_center())
	assert(game.mistakes_left == game.maximum_mistakes - 1)
	assert(not game.input_locked and following.selectable)
	game._on_card_selected(following)
	following.begin_external_drag(following.get_global_rect().get_center())
	await create_timer(0.45).timeout
	assert(game.selected_card == following and following.dragging,
		"Previous mistake feedback must preserve the next drag")
	game.mistakes_left = 1
	following.card_value = 0
	game._on_card_drag_released(following, game.piles[0].get_global_rect().get_center())
	assert(game.mistakes_left == 0 and game.input_locked)
	for remaining in game.hand_manager.interactive_cards():
		assert(not remaining.selectable)
	await create_timer(3.0).timeout
	assert(game.input_locked, "Lethal mistake must never reopen input")

	await _new_run()
	extra = await _grab_discard()
	game.mistakes_left = 1
	game._on_card_drag_released(extra, game.piles[1].get_global_rect().get_center())
	assert(game.mistakes_left == 0 and game.input_locked)
	assert(not DiscardPlayController.can_interact(game, extra))
	await create_timer(3.0).timeout
	assert(game.input_locked, "Discard release must not unlock the game after lethal damage")

	DifficultySettings.redraw_after_discard_play = true
	await _new_run()
	game.challenge_modifiers.shared_round_clock = true
	game._shared_clock_initialized = true
	game.timer_manager.time_left = 20.0
	game._handle_mistake(game.piles[0])
	assert(not game.input_locked and not game.timer_manager.running)
	game._handle_mistake(game.piles[1])
	assert(game.mistakes_left == game.maximum_mistakes - 2)
	await create_timer(1.5).timeout
	assert(game.timer_manager.running and not game._shared_clock_mistake_feedback_active)
	assert(game.timer_manager.time_left <= 20.0 and game.timer_manager.time_left > 18.0)

	await _new_run()
	extra = await _grab_discard()
	next_cards = game.hand_manager.current_cards.duplicate()
	await game._on_card_drag_released(extra, game.piles[0].get_global_rect().get_center())
	assert(game.hand_manager.current_cards != next_cards)
	var playable := false
	for card in game.hand_manager.current_cards:
		playable = playable or game._playable_values().has(card.card_value) or card.is_joker
	assert(playable, "Redrawing after an extra play must guarantee a playable card")

	await _new_run()
	extra = await _grab_discard()
	await game._restart_current_mode()
	assert(not is_instance_valid(extra))
	assert(game.hand_manager.discarding_cards.is_empty())
	assert(not game._discard_play_in_progress)
	while game.input_locked:
		await process_frame

	DifficultySettings.playable_discard_enabled = false
	game.timer_manager.stop_countdown()
	var card := game.hand_manager.current_cards[0]
	card.card_value = game.piles[0].expected_value()
	game.selected_card = card
	await game._place_selected_card(game.piles[0])
	assert(game.hand_manager.discarding_cards.is_empty(), "Feature switch must restore classic discard")
	DifficultySettings.playable_discard_enabled = true
	DifficultySettings.redraw_after_discard_play = false
	game.queue_free()
	await process_frame
	print("Playable discard tests passed.")
	quit()


func _new_run() -> void:
	await game.cleanup_special_rule_state(false)
	game.start_game(false, null, false, "DISCARD-TEST", {}, [], {
		"pile_count": 2, "hand_size": 3, "start_value": 5, "turn_time": 5.0,
	})
	while game.input_locked:
		await process_frame
	game.timer_manager.stop_countdown()
	await create_timer(0.4).timeout


func _grab_discard(wait_for_refill := true) -> PlayingCard:
	var first := game.hand_manager.current_cards[0]
	var extra := game.hand_manager.current_cards[1]
	first.card_value = 4
	extra.card_value = 3
	game.selected_card = first
	game._place_selected_card(game.piles[0])
	assert(extra.selectable, "The remaining hand must be selectable immediately on drop")
	var point := extra.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	# A press can now become a click selection; movement starts the drag.
	var drag_motion := InputEventMouseMotion.new()
	drag_motion.position = point + Vector2(0, -12)
	drag_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(drag_motion, true)
	await process_frame
	assert(extra.dragging and extra.discard_claimed)
	assert(extra.discard_tween == null or not extra.discard_tween.is_valid())
	if wait_for_refill:
		while game._discard_source_action_active:
			await process_frame
	return extra

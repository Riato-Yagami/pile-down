extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(12.0).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.start_game(false, null, false, "VISUAL-DISCARD", {}, [], {
		"pile_count": 2, "hand_size": 3, "start_value": 5, "turn_time": 20.0,
	})
	while game.input_locked:
		await process_frame
	await create_timer(0.4).timeout
	game.timer_manager.stop_countdown()
	var card := game.hand_manager.current_cards[0]
	# A flip finishing or being canceled after reparenting must never restore
	# an old hand-local Y into DragLayer.
	card.flip_down(true)
	await create_timer(0.03).timeout
	var before_reparent := card.global_position
	card.reparent(game.drag_layer, false)
	card.global_position = before_reparent
	game._discard_source_action_active = true
	game.hand_manager.track_discarding_card(card)
	assert(DiscardPlayController.claim_on_press(game, card))
	var claimed_y := card.global_position.y
	assert(is_equal_approx(claimed_y, before_reparent.y),
		"Canceling a flip after reparenting must preserve the tile's world position")
	await create_timer(0.18).timeout
	assert(is_equal_approx(card.global_position.y, claimed_y),
		"A claimed card must not jump to its previous hand-local Y")
	game.hand_manager.forget_card(card)
	card.queue_free()
	game.selected_card = null
	game.hand_manager.unlock_hand()
	card = game.hand_manager.current_cards[0]
	# Isolate the animated hit target from neighboring tiles that can overlap
	# its deliberately offset visual during the faster exit.
	for other in game.hand_manager.current_cards.duplicate():
		if other != card:
			game.hand_manager.forget_card(other)
			other.queue_free()
	card.flip_down(true)
	await create_timer(0.03).timeout
	# A retained/new hand may still be sliding into its slot when a bonus
	# redraw starts. Its visible position is independent of the HBox slot.
	card._entrance_home_positions[card.visual_root] = card.visual_root.position
	card._entrance_animation_running = true
	card.visual_root.position += Vector2(45, -35)
	var point := card.visual_root.get_global_transform() * (card.size * 0.5)
	assert(game._card_at_touch_position(point) == card, "Hit testing must follow the visible tile")
	game._discard_source_action_active = true
	game._discard_current_hand(true, true)
	assert(not card._flip_in_progress, "Discard must cancel the hand-local flip before reparenting")
	assert(not card._entrance_animation_running, "The exit must own the visual motion")
	await create_timer(0.08).timeout
	point = card.visual_root.get_global_transform() * (card.size * 0.5)
	assert(game._card_at_touch_position(point) == card)
	var press := InputEventScreenTouch.new()
	press.position = point
	press.pressed = true
	root.push_input(press, true)
	assert(card.discard_claimed, "Touching the visible tile must reserve the discard")
	await create_timer(0.35).timeout
	assert(is_instance_valid(card), "The reserved tile must survive its old exit deadline")
	game.queue_free()
	await process_frame
	print("Animated discard hit testing passed.")
	quit()

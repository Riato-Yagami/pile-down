class_name DiscardPlayController
extends RefCounted


static func open_window(host: GameManager, played_card: PlayingCard) -> void:
	host._discard_source_action_active = true
	host.selected_card = null
	for card in host.hand_manager.current_cards:
		if card == played_card or card.is_joker or host.drag_companions.has(card):
			continue
		host.hand_manager.track_discarding_card(card)
		card.set_selectable(true)


static func can_interact(host: GameManager, card: PlayingCard) -> bool:
	return (
		is_instance_valid(card) and card.is_discarding
		and host.Difficulty.playable_discard_enabled
		and host.mistakes_left > 0
		and host.hand_manager.discarding_cards.has(card)
		and not host._discard_play_in_progress
		and not host._screen_transition_active
		and not host.splash.visible and not host.overlay.visible
		and not host.quit_popup.visible and not host._quick_peek_pending
		and (not host.input_locked
			or host._discard_source_action_active
			or host._pending_interactive_generation == host._hand_cycle_generation)
	)


static func claim_on_press(host: GameManager, card: PlayingCard) -> bool:
	if not card.is_discarding:
		return true
	if not can_interact(host, card):
		return false
	host._on_card_selected(card)
	if host.selected_card != card:
		return false
	# Reserve before click/drag recognition: the exit can finish during a hold.
	card.claim_discard()
	# A click can keep the tile here through the next hand's container cleanup,
	# even though no drag ever starts to detach it from that container.
	if card.get_parent() != host.drag_layer:
		if card.get_parent() == host.hand_container:
			host._create_hand_slot_placeholder(card)
		var previous_position := card.global_position
		card.reparent(host.drag_layer, false)
		card.global_position = previous_position
	host.hand_manager.lock_all_cards_except(card)
	return true


static func cancel_claim(host: GameManager, card: PlayingCard) -> void:
	if not is_instance_valid(card) or not card.is_discarding or not card.discard_claimed:
		return
	if host.selected_card != card or host._discard_play_in_progress:
		return
	host._card_touch_index = -1
	CustomCursor.set_holding_card(false)
	release(host, card, null)


static func discard_covered_selection(host: GameManager) -> void:
	var card := host.selected_card
	if (
		not is_instance_valid(card) or not card.is_discarding
		or not card.discard_claimed or not card._selected or card.dragging
		or card._drag_starting or host._discard_play_in_progress
	):
		return
	var selected_rect := card.visual_root.get_global_transform() * Rect2(Vector2.ZERO, card.size)
	for incoming in host.hand_manager.current_cards:
		if incoming == card or not is_instance_valid(incoming) or not incoming.visible or incoming.modulate.a <= 0.05:
			continue
		var incoming_rect := incoming.visual_root.get_global_transform() * Rect2(Vector2.ZERO, incoming.size)
		if selected_rect.intersects(incoming_rect):
			cancel_claim(host, card)
			return


static func release(host: GameManager, card: PlayingCard, pile: MemoryPile) -> void:
	var generation := host._gameplay_generation
	card.finish_drag()
	card.set_selectable(false)
	host._discard_play_in_progress = true
	host._pending_interactive_generation = -1
	host.hand_manager.lock_hand()
	var exit_tween: Tween
	if pile == null:
		exit_tween = card.play_released_discard()
	# A second drop may arrive while the first card or its bonus chain is still
	# animating. Keep the grab responsive but serialize changes to pile values.
	while host._discard_source_action_active:
		await host.get_tree().process_frame
		if generation != host._gameplay_generation or not is_instance_valid(card):
			return
	if not card.is_discarding:
		return
	if not is_instance_valid(pile) or pile.completed:
		pile = null
	if pile == null or (not card.is_joker and not pile.can_accept(card.card_value)):
		host.hand_manager.forget_card(card)
		if exit_tween == null:
			exit_tween = card.play_released_discard()
		_free_after_exit(card, exit_tween)
		host.selected_card = null
		host._discard_play_in_progress = false
		if pile != null:
			host.input_locked = false
			await host._handle_mistake(pile)
			return
		if generation != host._gameplay_generation:
			return
		_finish(host)
		return

	host.input_locked = true
	var clock_was_running := host.timer_manager.running
	host._root_action_id += 1
	host._last_played_pile = pile
	var context := PlacementContext.new(PlacementContext.Source.PLAYER, host._root_action_id)
	var redraw := host.Difficulty.redraw_after_discard_play
	if redraw:
		# Transfer ownership before yielding to the placement animation. The
		# following hand offers the same early grab as an ordinary valid play.
		# A later release waits on source_action_active before changing a pile.
		host.hand_manager.forget_card(card)
		host.hand_manager.clear_discarding_cards()
		open_window(host, card)
		host._discard_play_in_progress = false
	# This card belongs to the old hand. Bonus chains must not consume the new one.
	await host._stack_card(card, pile, context)
	if generation != host._gameplay_generation:
		return
	await host._finalize_placement_action([pile])
	if generation != host._gameplay_generation:
		return
	var summary := HandComboSummary.new()
	summary.root_action_id = context.root_action_id
	summary.bonus_levels = host.bonus_manager.active_levels()
	host.achievement_manager.hand_combo_resolved.emit(summary)
	if not redraw:
		host.selected_card = null
		host._discard_play_in_progress = false
	if host._all_piles_complete():
		host._discard_source_action_active = false
		await host._finish_round()
		return
	if redraw:
		host._hand_cycle_generation += 1
		host._start_discard_current_hand(true, true)
		if is_instance_valid(host.selected_card) and host.selected_card.is_discarding:
			host.hand_manager.lock_all_cards_except(host.selected_card)
		await host._begin_turn(false, true)
		if generation == host._gameplay_generation:
			host._discard_source_action_active = false
		return
	_finish(host)
	if clock_was_running and host.timer_manager.time_left <= 0.0 and not host.input_locked:
		host._on_time_expired()


static func _free_after_exit(card: PlayingCard, tween: Tween) -> void:
	if tween.is_valid() and tween.is_running():
		await tween.finished
	if is_instance_valid(card):
		card.queue_free()


static func _finish(host: GameManager) -> void:
	host._discard_play_in_progress = false
	host.selected_card = null
	host._card_touch_index = -1
	CustomCursor.set_holding_card(false)
	if host.overlay.visible or host._screen_transition_active:
		return
	host.input_locked = false
	host.hand_manager.clear_selection()
	host.hand_manager.unlock_hand()
	host._resolve_pending_shared_clock_timeout()

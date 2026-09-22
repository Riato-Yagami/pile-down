class_name CardPlacementController
extends RefCounted

## Card placement, chained bonuses and mistake resolution.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func place_selected_card(host: GameManager, pile: MemoryPile) -> void:
	host._hand_cycle_generation += 1
	var placement_generation := host._hand_cycle_generation
	host.input_locked = true
	if host.challenge_modifiers.shared_round_clock:
		host.timer_manager.add_time(host.bonus_manager.shared_clock_time_bonus(host.turn_time))
	else:
		host.bonus_manager.bank_remaining_time(host.timer_manager.time_left)
		host.timer_manager.stop_countdown()
	host.hand_manager.lock_hand()
	var card := host.selected_card
	var placed_value := pile.expected_value() if card.is_joker else card.card_value
	var origin := card.global_position
	host._root_action_id += 1
	var context := PlacementContext.new(PlacementContext.Source.PLAYER, host._root_action_id)
	var combo_summary := HandComboSummary.new()
	combo_summary.root_action_id = context.root_action_id
	combo_summary.bonus_levels = host.bonus_manager.active_levels()
	var affected_piles: Array[MemoryPile] = []
	await host._stack_card(card, pile, context)
	affected_piles.append(pile)
	combo_summary.bring_a_friend_total_companions = host.drag_companions.size()
	var companion_piles := await host._resolve_companion_drops(pile)
	combo_summary.bring_a_friend_count = companion_piles.size()
	combo_summary.bring_a_friend_all_succeeded = (
		combo_summary.bring_a_friend_total_companions > 0
		and combo_summary.bring_a_friend_count
		== combo_summary.bring_a_friend_total_companions
	)
	for companion_pile in companion_piles:
		if not affected_piles.has(companion_pile):
			affected_piles.append(companion_pile)
	if host.bonus_manager.has_bonus(&"deja_vu"):
		var deja_piles := await host._resolve_deja_vu(
			placed_value, pile, host.bonus_manager.level(&"deja_vu"), origin, context.root_action_id
		)
		combo_summary.deja_vu_count = deja_piles.size()
		for deja_pile in deja_piles:
			if not affected_piles.has(deja_pile):
				affected_piles.append(deja_pile)
	if host.bonus_manager.has_bonus(&"double_down") and not pile.completed:
		combo_summary.double_down_count = await host._resolve_double_down(
			pile, host.bonus_manager.level(&"double_down"), origin, context.root_action_id
		)
	if not affected_piles.has(pile):
		affected_piles.append(pile)
	await host._finalize_placement_action(affected_piles)
	host.achievement_manager.hand_combo_resolved.emit(combo_summary)
	if host._all_piles_complete():
		await host._finish_round()
		return
	if host.challenge_modifiers.conveyor_hand:
		host.selected_card = null
		host.input_locked = false
		host.hand_manager.unlock_hand()
		host._start_turn_countdown(host.bonus_manager.next_hand_time(host.turn_time))
		return
	await host._discard_current_hand()
	if placement_generation == host._hand_cycle_generation:
		await host._begin_turn(false, true)


static func stack_card(
	host: GameManager,
	card: PlayingCard,
	pile: MemoryPile,
	context: PlacementContext
) -> void:
	if not is_instance_valid(card) or not is_instance_valid(pile) or pile.completed:
		return
	if card.get_parent() != host.drag_layer:
		var previous_global_position := card.global_position
		if card.get_parent() == host.hand_container:
			host._create_hand_slot_placeholder(card)
		card.reparent(host.drag_layer, false)
		card.global_position = previous_global_position
	if card.get_parent() == host.drag_layer:
		host.drag_layer.move_child(card, host.drag_layer.get_child_count() - 1)
	if context.source == PlacementContext.Source.DOUBLE_DOWN:
		await host.get_tree().create_timer(0.05).timeout
	card.confirm_drop()
	var destination := pile.global_position + (pile.size - card.size) * 0.5
	var placement_duration := (
		host.Difficulty.BONUS_CHAIN_PLACEMENT_DURATION
		if (
			context.source == PlacementContext.Source.DOUBLE_DOWN
			or context.source == PlacementContext.Source.DEJA_VU
		)
		else host.Difficulty.AUTOMATIC_PLACEMENT_DURATION
	)
	await card.animate_valid_drop(destination, placement_duration)
	var placed_value := pile.expected_value() if card.is_joker else card.card_value
	pile.place(placed_value)
	var pile_values: Array[int] = []
	for round_pile in host.piles:
		pile_values.append(round_pile.current_value)
	host.achievement_manager.pile_placement_resolved.emit(
		host.piles.find(pile), pile_values, pile.is_complete_value()
	)
	host.background_effects.emit_tile_impact_wave(
		pile.get_global_rect().abs().get_center()
	)
	if host.bonus_manager.has_bonus(&"last_reminder") and not pile.is_complete_value():
		if (
			host._last_reminder_pile != null
			and is_instance_valid(host._last_reminder_pile)
			and host._last_reminder_pile != pile
			and not host._last_reminder_pile.bonus_highlight
		):
			host._last_reminder_pile.keep_face_up = false
			host._last_reminder_pile.set_bonus_revealed(false)
		pile.keep_face_up = true
		host._last_reminder_pile = pile
	host.card_placed.emit(card, pile)
	host.soft_audio.play_tone(610.0, 0.075, 0.055)
	card.visible = false
	host.hand_manager.forget_card(card)
	card.queue_free()


static func resolve_deja_vu(
	host: GameManager,
	played_value: int,
	original_pile: MemoryPile,
	maximum_copies: int,
	origin: Vector2,
	root_action_id: int
) -> Array[MemoryPile]:
	var matching_cards := host.hand_manager.find_cards_with_value(played_value)
	var compatible_piles := host.pile_manager.find_piles_accepting_value(played_value)
	compatible_piles.erase(original_pile)
	matching_cards.sort_custom(
		func(first: PlayingCard, second: PlayingCard) -> bool:
			return first.global_position.distance_squared_to(origin) < second.global_position.distance_squared_to(origin)
	)
	var used: Array[MemoryPile] = []
	for card in matching_cards:
		if used.size() >= maximum_copies or compatible_piles.is_empty():
			break
		compatible_piles.sort_custom(
			func(first: MemoryPile, second: MemoryPile) -> bool:
				var card_center := card.global_position + card.size * 0.5
				var first_distance := card_center.distance_squared_to(first.global_position + first.size * 0.5)
				var second_distance := card_center.distance_squared_to(second.global_position + second.size * 0.5)
				if is_equal_approx(first_distance, second_distance):
					return first.pile_index < second.pile_index
				return first_distance < second_distance
		)
		var target := compatible_piles.pop_front() as MemoryPile
		await host._stack_card(
			card, target,
			PlacementContext.new(PlacementContext.Source.DEJA_VU, root_action_id)
		)
		used.append(target)
	return used


static func resolve_double_down(
	host: GameManager,
	pile: MemoryPile,
	maximum_bonus_cards: int,
	origin: Vector2,
	root_action_id: int
) -> int:
	var played_count := 0
	while played_count < maximum_bonus_cards and not pile.is_complete_value():
		var matching_card := host.hand_manager.find_card_with_value(pile.expected_value(), origin)
		if matching_card == null:
			break
		await host._stack_card(
			matching_card, pile,
			PlacementContext.new(PlacementContext.Source.DOUBLE_DOWN, root_action_id)
		)
		played_count += 1
	return played_count


static func finalize_placement_action(host: GameManager, affected_piles: Array[MemoryPile]) -> void:
	for pile in affected_piles:
		if not is_instance_valid(pile):
			continue
		if pile.is_complete_value() and not pile.completed:
			await host._complete_pile(pile)
	for pile in affected_piles:
		if is_instance_valid(pile) and not pile.completed:
			await host.get_tree().create_timer(0.08).timeout
			await pile.hide_value(true)
	await host._after_valid_card_played()


static func complete_pile(host: GameManager, pile: MemoryPile) -> void:
	if pile.completed:
		return
	host.soft_audio.play_tone(760.0, 0.14, 0.06)
	if is_instance_valid(host.dust_pool):
		host.dust_pool.emit_wave(
			pile.get_global_rect().abs().get_center(),
			host.dust_completion_wave_influence
		)
		host.background_effects.emit_wave(
			pile.get_global_rect().abs().get_center(),
			host.dust_completion_wave_influence
		)
	await pile.complete_animation(host._is_background_deformation_active())
	var recovered := host.bonus_manager.recover_on_completed_pile(
		host.mistakes_left,
		host.maximum_mistakes
	)
	if recovered != host.mistakes_left:
		host.mistakes_left = recovered
		host._update_hud()


static func after_valid_card_played(host: GameManager) -> void:
	await host.special_rule_manager.after_card_played(host.piles, host._progression_round())
	if host.round_modifiers.musical_stacks_enabled:
		var movement_duration := 0.4 / host.bonus_manager.adaptation_multiplier()
		if host.round_modifiers.moving_pile_pattern:
			await host.special_rule_manager.moving_pile_pattern.permute_paths(
				host.piles,
				host.round_modifiers.musical_stacks_direction,
				movement_duration
			)
		else:
			await host.pile_manager.rotate_active_piles(
				host.round_modifiers.musical_stacks_direction,
				movement_duration
			)


static func handle_mistake(
	host: GameManager,
	pile: MemoryPile = null,
	caused_by_timeout := false,
	force_damage := false,
	instant_death := false,
	damage_type := GameManager.DamageType.WRONG_PLACEMENT
) -> void:
	if host.input_locked:
		return
	var gameplay_generation := host._gameplay_generation
	host.input_locked = true
	var shared_clock_time := host.timer_manager.time_left
	host.timer_manager.stop_countdown()
	host.hand_manager.lock_hand()
	host.run_mistake_count += 1
	if caused_by_timeout:
		damage_type = (
			host.DamageType.SUDDEN_DEATH if instant_death else host.DamageType.TIMER_TIMEOUT
		)
	if GameManager.breaks_flawless(damage_type):
		host.flawless_since_last_bonus = false
	var protected_by_safety_net := (
		false if force_damage else host.bonus_manager.consume_safety_net()
	)
	if force_damage or (not host.Debug.is_god_mode_enabled() and not protected_by_safety_net):
		host.mistakes_left = 0 if instant_death else host.mistakes_left - 1
		host.run_lives_lost += 1
		host.checkpoint_segment_damage_count += 1
		host.achievement_manager.life_lost.emit()
	host.mistake_made.emit()
	if protected_by_safety_net:
		host.soft_audio.play_safety_net_break()
	elif caused_by_timeout:
		host.soft_audio.play_timeout_error()
	else:
		host.soft_audio.play_error()
	if host.mistakes_left <= 0:
		host.music_manager.set_low_pass_enabled(true)
	if protected_by_safety_net:
		await host.mistakes_dots.play_safety_net_break()
	else:
		await host.mistakes_dots.play_damage(host.mistakes_left)
	if not is_instance_valid(host) or gameplay_generation != host._gameplay_generation:
		return
	host._update_hud()
	await host._return_drag_companions()
	if not is_instance_valid(host) or gameplay_generation != host._gameplay_generation:
		return
	if host.selected_card != null and is_instance_valid(host.selected_card) and host.selected_card.get_parent() == host.drag_layer:
		if host.challenge_modifiers.conveyor_hand and not caused_by_timeout:
			await host._discard_rejected_conveyor_card(host.selected_card)
		else:
			await host._return_card_to_hand(host.selected_card, 0.14)
	if not is_instance_valid(host) or gameplay_generation != host._gameplay_generation:
		return
	if host.mistakes_left <= 0:
		await host.get_tree().create_timer(host.DEATH_POPUP_DELAY).timeout
		if not is_instance_valid(host) or gameplay_generation != host._gameplay_generation:
			return
		await host._reveal_piles_before_game_over()
		if not is_instance_valid(host) or gameplay_generation != host._gameplay_generation:
			return
		host._start_discard_current_hand(false)
		await host._finish_game()
	else:
		host.selected_card = null
		host.hand_manager.clear_selection()
		if host.bonus_manager.has_bonus(&"mistake_reveal"):
			await host._run_bonus_pile_flash(
				host.Difficulty.MISTAKE_REVEAL_DURATIONS[
					host.bonus_manager.level(&"mistake_reveal")
				]
			)
			if not is_instance_valid(host) or gameplay_generation != host._gameplay_generation:
				return
		var wait_for_shared_clock_feedback := (
			host.challenge_modifiers.shared_round_clock
			and pile != null
			and is_instance_valid(pile)
			and not pile.completed
		)
		# Input returns before the pile feedback finishes so another tile can be
		# dragged immediately. Shared Clock itself remains frozen until the
		# animation has fully resolved.
		host._shared_clock_mistake_feedback_active = wait_for_shared_clock_feedback
		host.input_locked = false
		host.hand_manager.unlock_hand()
		if wait_for_shared_clock_feedback:
			await host._reveal_mistake_pile(pile)
			if not is_instance_valid(host) or gameplay_generation != host._gameplay_generation:
				return
			host._shared_clock_mistake_feedback_active = false
		if host.challenge_modifiers.shared_round_clock:
			if not caused_by_timeout and not host.input_locked and not host.overlay.visible:
				host.timer_manager.time_left = maxf(
					shared_clock_time - host.Difficulty.SHARED_CLOCK_LIFE_PENALTY,
					0.0
				)
				host._start_turn_countdown()
		else:
			host._start_turn_countdown()
		if (
			not host.challenge_modifiers.shared_round_clock
			and pile != null
			and is_instance_valid(pile)
			and not pile.completed
		):
			host._reveal_mistake_pile(pile)


static func reveal_mistake_pile(host: GameManager, pile: MemoryPile) -> void:
	await pile.flash_invalid()
	if is_instance_valid(pile) and not pile.completed:
		await pile.reveal_value_temporarily(0.65)


static func reveal_piles_before_game_over(host: GameManager) -> void:
	var final_tween: Tween
	for pile in host.piles:
		if not is_instance_valid(pile) or not pile.visible or pile.completed:
			continue
		final_tween = pile.reveal_for_game_over()
	if final_tween != null and final_tween.is_valid():
		await final_tween.finished
	await host.get_tree().create_timer(host.DEATH_PILE_REVEAL_HOLD_DURATION).timeout

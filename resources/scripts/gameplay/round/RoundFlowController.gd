class_name RoundFlowController
extends RefCounted

## Round setup, hand generation and round-completion sequencing.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func start_round(host: GameManager) -> void:
	var gameplay_generation := host._gameplay_generation
	host._resume_run_time()
	host.input_locked = true
	if (
		host._background_enabled
		and host.background_manager.dynamic_presets_enabled
		and (
			host.background_manager.current_layer == null
			or not host.background_manager.current_layer.visible
		)
	):
		host.background_manager.start_run(host.cosmetic_rng)
	host._emit_difficulty_stats()
	host._round_mistakes_at_start = host.run_mistake_count
	host._capture_checkpoint_candidate()
	host.sticky_fingers_controller.end_round()
	host.mirror_match_controller.end_round(host)
	host._regeneration_hand_check_pending = false
	host.selected_card = null
	host.hovered_pile = null
	host.maximum_mistakes = 3
	host._last_clock_second = -1
	host._urgent_tick_index = 0
	host.timer_manager.stop_countdown()
	host._shared_clock_initialized = false
	host._shared_clock_timeout_pending = false
	host._conveyor_active = false
	host.hand_manager.clear_hand(host.hand_container)
	host._clear_drag_placeholder()
	for child in host.drag_layer.get_children():
		child.queue_free()
	for child in host.piles_board.get_children():
		child.queue_free()
	host.piles.clear()
	host._last_reminder_pile = null
	host.bonus_manager.begin_round()
	host.round_modifiers = await host.special_rule_manager.begin_round(host._progression_round())
	if gameplay_generation != host._gameplay_generation:
		return
	host.round_modifiers.hide_tile_numbers = host.challenge_modifiers.hide_tile_numbers
	var rule_intensity := host.bonus_manager.adaptation_multiplier()
	if host.round_modifiers.hot_potatoes_enabled:
		host.round_modifiers.hot_potato_drag_duration /= rule_intensity
	host.sticky_fingers_controller.begin_round(
		host.round_modifiers.sticky_fingers_enabled
	)
	if host.round_modifiers.mirror_match_enabled:
		host.mirror_match_controller.begin_round(host, host.round_modifiers)
	host.maximum_mistakes = (
		1
		if host.challenge_modifiers.force_single_life
		else host.round_modifiers.maximum_mistakes_override
		if host.round_modifiers.maximum_mistakes_override > 0
		else 3 + host.bonus_manager.spare_lives()
	)
	host.mistakes_left = host.maximum_mistakes
	host.mistakes_dots.set_maximum(host.maximum_mistakes)
	host.mistakes_dots.set_reinforced_count(
		0
		if host.round_modifiers.sudden_death_enabled
		else host.bonus_manager.spare_lives()
	)
	host.mistakes_dots.set_safety_net_active(
		host.bonus_manager.safety_net_available
	)

	for index in host.pile_count:
		var pile := host.PILE_SCENE.instantiate() as MemoryPile
		host.piles_board.add_child(pile)
		var selected_palette_data := host.palette_manager.find(
			host.palette_manager.selected_palette
		)
		if selected_palette_data != null:
			pile.set_tile_palette(selected_palette_data.normalized_colors())
		var selected_font_data := host.font_manager.find(host.font_manager.selected_font)
		if selected_font_data != null:
			pile.set_value_font(
				selected_font_data.font,
				selected_font_data.tile_font_size,
				selected_font_data.tile_font_offset,
				selected_font_data.override_hidden_tile_with_font
			)
		pile.setup(
			index,
			host.start_value,
			host.round_modifiers.stack_direction,
			host.round_modifiers.roman_numerals_enabled,
			host.round_modifiers.colorblind_enabled,
			host.round_modifiers.hide_tile_numbers
		)
		pile.set_movable(host.bonus_manager.has_bonus(&"pile_mover"))
		pile.pile_selected.connect(host._on_pile_selected)
		pile.drag_requested.connect(host._on_pile_drag_requested)
		pile.drag_released.connect(host._on_pile_drag_released)
		pile.regenerated.connect(host._on_pile_regenerated)
		host.piles.append(pile)
	host.achievement_manager.pile_round_started.emit(
		host.piles.size(), host.round_modifiers.stack_direction == RoundModifiers.StackDirection.DOWN
	)
	host._layout_piles()
	host._replay_board_ready = true
	for index in host.piles.size():
		host.piles[index].play_entrance(index * 0.055)
	var open_book_count := host.bonus_manager.level(&"open_book")
	if open_book_count > 0:
		var open_book_candidates := host.piles.duplicate()
		host._shuffle_with_rng(open_book_candidates, host.run_rng.get_stream(&"bonuses"))
		for index in mini(open_book_count, open_book_candidates.size()):
			open_book_candidates[index].keep_face_up = true
	host._update_hud()
	# Start the readable hold only once the final entrance has completed. The old
	# timing included entrance motion, leaving the number legible for too little
	# time before its flip.
	var last_pile_entrance_delay := maxf(float(host.piles.size() - 1) * 0.055, 0.0)
	var pile_reveal_duration := (
		last_pile_entrance_delay + 0.25 + host.pile_value_hold_duration
	)
	if host._restart_pile_reveal_pending:
		pile_reveal_duration += host.RESTART_PILE_REVEAL_BONUS
	host._restart_pile_reveal_pending = false
	await host.get_tree().create_timer(
		0.0 if host._debug_action_in_progress else pile_reveal_duration
	).timeout
	if gameplay_generation != host._gameplay_generation:
		return
	# Continuous movement owns pile.position, so start it only after every
	# entrance tween has released that property. Position-dependent board
	# effects are generated afterwards from the final movement layout.
	await host.special_rule_manager.activate_board_effects(host.piles, host._progression_round())
	if gameplay_generation != host._gameplay_generation:
		return
	if host.round_modifiers.floor_is_lava_enabled:
		host.lava_rule_controller.generate(
			host._progression_round(),
			host.piles,
			host.hand_container,
			host.timer_ring,
			host.lava_layer,
			host.run_rng.get_stream(&"movement")
		)
	for pile in host.piles:
		if is_instance_valid(pile):
			pile.hide_value(true)
	await host.get_tree().create_timer(0.0 if host._debug_action_in_progress else 0.26).timeout
	if gameplay_generation != host._gameplay_generation:
		return
	host._begin_turn()


static func layout_piles(host: GameManager) -> void:
	if host.piles.is_empty() or host.piles_board.size.x <= 0.0:
		return
	var piece_size := 37.0
	var gap := 7.0
	var positions := PileLayoutManager.positions_for_2d(host.pile_count, piece_size, gap)
	var center := host.piles_board.size * 0.5
	var slots: Array[Vector2] = []
	for index in mini(host.piles.size(), positions.size()):
		var pile := host.piles[index]
		pile.custom_minimum_size = Vector2(34.0, 37.0)
		pile.size = Vector2(34.0, 37.0)
		pile.position = (center + positions[index] - Vector2(17.0, 18.0)).round()
		slots.append(pile.position)
	host.pile_manager.configure(host.piles_board, host.piles, slots)


static func begin_turn(
	host: GameManager,
	hand_prepared := false,
	enter_from_right := false,
	preserve_timer := false
) -> void:
	if host._all_piles_complete():
		# Debug round skipping can reach this point while the previous completed
		# board is being replaced; never leave the transition permanently locked.
		host.input_locked = false
		return
	host.selected_card = null
	host.input_locked = true
	if not hand_prepared:
		if enter_from_right:
			host._generate_next_hand(
				host._hand_cycle_generation, true, true, not preserve_timer
			)
		else:
			await host._prepare_next_hand(true, false)
	if host._quick_peek_pending:
		return
	if enter_from_right:
		host._pending_interactive_generation = host._hand_cycle_generation
		# Deferred entrance methods mark themselves running after layout. Wait
		# one frame before deciding that a hand contains retained cards only.
		await host.get_tree().process_frame
		if host._pending_interactive_generation != host._hand_cycle_generation:
			return
		if not host.hand_manager.current_cards.any(
			func(card: PlayingCard) -> bool:
				return (
					is_instance_valid(card)
					and card._entrance_animation_running
				)
		):
			host._pending_interactive_generation = -1
			host.input_locked = false
			host.hand_manager.unlock_hand()
			host._resolve_pending_shared_clock_timeout()
		return
	host.input_locked = false
	host.hand_manager.unlock_hand()
	host._resolve_pending_shared_clock_timeout()


static func prepare_next_hand(
	host: GameManager, clear_existing: bool, enter_from_right: bool
) -> void:
	var requested_generation := host._hand_cycle_generation
	if host._restart_hand_immediate_pending:
		host._restart_hand_immediate_pending = false
	elif not host._debug_action_in_progress:
		await host.music_manager.wait_for_next_hand_beat()
	host._generate_next_hand(requested_generation, clear_existing, enter_from_right)


static func generate_next_hand(
	host: GameManager,
	requested_generation: int,
	clear_existing: bool,
	enter_from_right: bool,
	start_timer := true
) -> void:
	if requested_generation != host._hand_cycle_generation or host._all_piles_complete():
		return
	var wandering_cards := host.round_modifiers.wandering_hand_cards
	if clear_existing:
		host._clear_all_hand_slot_placeholders()
	if host.challenge_modifiers.conveyor_hand:
		if not host._conveyor_active:
			host._start_conveyor()
		host._start_turn_countdown(host.bonus_manager.next_hand_time(host.turn_time))
		host.redraw_button.visible = false
		host._quick_peek_pending = false
		return
	var force_reload_tutorial_hand := host._reload_tutorial_hand_pending
	host._reload_tutorial_hand_pending = false
	host.hand_manager.generate_hand(
		host.drag_layer if wandering_cards else host.hand_container,
		host.hand_size,
		host.start_value,
		host._playable_values_with_duplicates(),
		host.round_modifiers.stack_direction == RoundModifiers.StackDirection.UP,
		host.round_modifiers.hover_reveal_enabled,
		host.round_modifiers.roman_numerals_enabled,
		not wandering_cards,
		clear_existing,
		enter_from_right,
		host.round_modifiers,
		host.bonus_manager.joker_chance(),
		host.bonus_manager.consume_forced_joker(),
		host.bonus_manager.lucky_hand_chance(),
		host.bonus_manager.level(&"lucky_hand"),
		host.bonus_manager.level(&"double_down"),
		host.bonus_manager.level(&"deja_vu"),
		host.piles,
		host.challenge_modifiers.guarantee_playable_hand,
		force_reload_tutorial_hand
	)
	if wandering_cards:
		host._draw_wandering_hand()
	var challenge_reload := (
		host.game_mode == host.GameMode.CHALLENGE
		and host.current_challenge.id == &"reload_required"
	)
	host.redraw_button.set_as_hand_slot(host.hand_container, false)
	host.redraw_button.visible = (
		(challenge_reload or host.bonus_manager.redraws_left > 0)
		and not wandering_cards
	)
	# Reload is always visible in its challenge, so its hover feedback is the
	# icon highlight rather than a tooltip popup over the hand.
	host.redraw_button.tooltip_text = "" if challenge_reload else "REDRAW"
	host.redraw_button.set_remaining(
		host.bonus_manager.redraws_left,
		host.bonus_manager.level(&"redraw") >= 2
	)
	host._quick_peek_pending = host.bonus_manager.should_trigger_quick_peek()
	if host._quick_peek_pending:
		host.input_locked = true
		host.hand_manager.lock_hand()
		host.call_deferred("_run_quick_peek")
	elif start_timer:
		host._start_turn_countdown(host.bonus_manager.next_hand_time(host.turn_time))


static func draw_wandering_hand(host: GameManager) -> void:
	var occupied: Array[Rect2] = []
	for pile in host.piles:
		if is_instance_valid(pile) and not pile.completed:
			occupied.append(pile.get_global_rect().abs().grow(5.0))
	for index in host.hand_manager.current_cards.size():
		var card := host.hand_manager.current_cards[index]
		if not is_instance_valid(card):
			continue
		var position_candidate := Vector2.ZERO
		for attempt in 24:
			position_candidate = Vector2(
				host.run_rng.get_stream(&"movement").randi_range(38, 184),
				host.run_rng.get_stream(&"movement").randi_range(58, 190)
			)
			var card_rect := Rect2(position_candidate, Vector2(34.0, 37.0))
			if not occupied.any(func(rect: Rect2) -> bool: return rect.intersects(card_rect)):
				break
		card.global_position = position_candidate.round()
		occupied.append(card.get_global_rect().abs().grow(5.0))
		card.play_wandering_entrance(
			index,
			position_candidate.round(),
			host.size,
			index * 0.055
		)


static func finish_round(host: GameManager) -> void:
	host.input_locked = true
	var transition_generation := host._run_transition_generation
	var completed_round_number := host._progression_round()
	var completed_rule_ids: Array[StringName] = []
	for rule in host.special_rule_manager.active_rules:
		completed_rule_ids.append(rule.id)
	host._pause_run_time()
	host.timer_manager.stop_countdown()
	await host.cleanup_special_rule_state()
	if transition_generation != host._run_transition_generation:
		return
	# Clear the remaining hand as part of the victory sequence. Jokers persist
	# between hands, but never carry over into the next round.
	await host._discard_current_hand(false)
	if transition_generation != host._run_transition_generation:
		return
	host._clear_all_hand_slot_placeholders()
	await host.special_rule_manager.end_round(host.piles)
	if transition_generation != host._run_transition_generation:
		return
	host.round_completed.emit()
	host.run_completed_rounds += 1
	for rule_id in completed_rule_ids:
		if not host.beaten_special_rules.has(rule_id):
			host.beaten_special_rules.append(rule_id)
	host._save_discoveries()
	host.achievement_manager.special_rule_round_completed.emit(
		completed_rule_ids, host.beaten_special_rules
	)
	host.achievement_manager.round_completed.emit(
		host._build_run_summary(false), completed_round_number, completed_rule_ids
	)
	var checkpoint_unlocked := (
		false
		if host.game_mode == host.GameMode.CHALLENGE
		else host._unlock_completed_checkpoint(completed_round_number)
	)
	if checkpoint_unlocked:
		host.achievement_manager.checkpoint_unlocked.emit(
			int(completed_round_number / host.Difficulty.CHECKPOINT_INTERVAL),
			host.unlocked_checkpoints
		)
		await host._show_checkpoint_unlocked(
			int(completed_round_number / host.Difficulty.CHECKPOINT_INTERVAL)
		)
		if transition_generation != host._run_transition_generation:
			return
	host.soft_audio.play_tone(680.0, 0.16, 0.055)
	await host._show_round_wave()
	if transition_generation != host._run_transition_generation:
		return
	if (
		host.game_mode in [host.GameMode.ENDLESS, host.GameMode.CHECKPOINT]
		or (host.game_mode == host.GameMode.CHALLENGE and host.challenge_endless)
	):
		host.round_number += 1
	else:
		host.round_number -= 1
	host.round_reached_time_ms = host._total_time_milliseconds()
	host._update_hud()
	if host.game_mode == host.GameMode.STANDARD and host.round_number <= 0:
		await host._finish_game(true)
		return
	if (
		host.game_mode == host.GameMode.CHALLENGE
		and not host.challenge_endless
		and host.round_number <= 0
	):
		await host._finish_game(true)
		return
	if (
		host.game_mode == host.GameMode.CHECKPOINT
		and not host.checkpoint_uses_endless_progression
		and host.round_number > host.Difficulty.TOTAL_ROUNDS
	):
		await host._finish_game(true)
		return
	var flawless_bonus := (
		(
			host.Difficulty.ENABLE_FLAWLESS_BONUS_CHOICE
			and host.flawless_since_last_bonus
			and host.checkpoint_bonus_backlog <= 0
			and not host.Debug.DISABLE_FLAWLESS
		)
		or host.Debug.FORCE_FLAWLESS
	)
	var bonus_choice_count := (
		host.Difficulty.FLAWLESS_BONUS_CHOICE_COUNT
		if flawless_bonus else host.Difficulty.BONUS_CHOICE_COUNT
	)
	if await host.bonus_manager.offer_if_due(
		completed_round_number, bonus_choice_count, flawless_bonus
	):
		host.flawless_since_last_bonus = true
	if transition_generation != host._run_transition_generation:
		return
	await host._offer_checkpoint_backlog_bonus(completed_round_number)
	if transition_generation != host._run_transition_generation:
		return
	var change := host._advance_difficulty(host._progression_round())
	host._emit_difficulty_stats()
	if change == "TIER RELIEF":
		host.music_manager.request_next_section()
		if not host.Debug.DISABLE_BG_MORPH_TRANSITION:
			host.background_manager.transition_to_next(host.cosmetic_rng)
		else:
			host.background_manager.transition_to_next(host.cosmetic_rng)
			host.background_manager.skip_transition()
	if change.is_empty():
		if host._debug_round_wins_queued > 0:
			return
		host.start_round()
		return
	host._pause_achievement_notifications(&"difficulty")
	var change_lines := change.split("\n", false)
	var tween := host.DifficultyAnnouncementScript.animate(
		host.transient_label, change_lines,
		host.extra_difficulty_reveal_delay, host.extra_difficulty_hold_duration
	)
	host.skippable_sequence.begin(tween)
	if not host.skippable_sequence.skipped.is_connected(host.background_manager.skip_transition):
		host.skippable_sequence.skipped.connect(host.background_manager.skip_transition)
	if host._debug_round_wins_queued > 0:
		host.skippable_sequence.call_deferred("skip_to_end")
	await tween.finished
	if transition_generation != host._run_transition_generation:
		host.skippable_sequence.finish()
		host.transient_label.visible = false
		host._resume_achievement_notifications(&"difficulty")
		return
	host.skippable_sequence.finish()
	host.transient_label.visible = false
	host._resume_achievement_notifications(&"difficulty")
	if host._debug_round_wins_queued > 0:
		return
	host.start_round()


static func show_round_wave(host: GameManager) -> void:
	# The deformable background emits its own completion wave.
	if host._is_background_deformation_active():
		return
	host._pause_achievement_notifications(&"round_wave")
	var wave := host.round_wave
	wave.visible = true
	wave.scale = Vector2(0.2, 0.2)
	wave.modulate.a = 0.45
	var tween := host.create_tween().set_parallel()
	tween.tween_property(wave, "scale", Vector2(2.4, 2.4), 0.55)
	tween.tween_property(wave, "modulate:a", 0.0, 0.55)
	host.skippable_sequence.begin(tween)
	if host._debug_round_wins_queued > 0:
		host.skippable_sequence.call_deferred("skip_to_end")
	await tween.finished
	host.skippable_sequence.finish()
	wave.visible = false
	host._resume_achievement_notifications(&"round_wave")

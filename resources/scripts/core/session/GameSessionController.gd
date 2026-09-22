class_name GameSessionController
extends RefCounted

## Run start, restart, return-to-menu and final-result orchestration.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func start_game(
	host: GameManager,
	endless_mode := false,
	challenge_data: ChallengeData = null,
	challenge_is_endless := false,
	requested_seed := "",
	seed_bonuses: Variant = [],
	seed_rule_ids: Array[StringName] = [],
	seed_difficulty: Dictionary = {}
) -> void:
	host._gameplay_generation += 1
	var effective_seed := requested_seed.strip_edges()
	if effective_seed.is_empty() and host.Debug.ENABLED:
		effective_seed = host.Debug.FORCE_RUN_SEED.strip_edges()
	host.run_uses_requested_seed = not effective_seed.is_empty()
	var seed_bonus_levels := host._normalise_seed_bonus_levels(seed_bonuses)
	var sanitized_seed_difficulty := host._sanitized_seed_difficulty(seed_difficulty)
	host.run_seed_bonus_levels = seed_bonus_levels.duplicate()
	host.run_seed_difficulty = sanitized_seed_difficulty.duplicate()
	host.run_seed_bonus_ids.clear()
	for bonus_id in seed_bonus_levels:
		host.run_seed_bonus_ids.append(StringName(bonus_id))
	host.run_seed_rule_ids.assign(seed_rule_ids)
	if effective_seed.is_empty():
		host._initialize_run_rng(host.RunRNGScript.generate_run_seed())
	else:
		host._initialize_run_rng(
			host.RunRNGScript.seed_string_to_int(effective_seed), effective_seed
		)
	var animate_menu_exit := host.splash.visible
	host.gameplay_layer.visible = true
	host.back_button.visible = not animate_menu_exit
	host.current_challenge = challenge_data
	host.challenge_endless = challenge_is_endless
	host._reload_tutorial_hand_pending = (
		challenge_data != null and challenge_data.id == &"reload_required"
	)
	host.challenge_modifiers = (
		host.challenge_manager.modifiers_for(host.current_challenge)
		if host.current_challenge != null
		else ChallengeModifiers.new()
	)
	host._configure_challenge_hand_tray()
	host.bonus_manager.disabled_bonus_ids.assign(host.challenge_modifiers.disabled_bonuses)
	host.special_rule_manager.disabled_rule_ids.assign(host.challenge_modifiers.disabled_special_rules)
	host.special_rule_manager.forced_rule_ids.assign(
		host.current_challenge.forced_rules if host.current_challenge != null else []
	)
	for rule_id in seed_rule_ids:
		if (
			not host.special_rule_manager.disabled_rule_ids.has(rule_id)
			and not host.special_rule_manager.forced_rule_ids.has(rule_id)
		):
			host.special_rule_manager.forced_rule_ids.append(rule_id)
	host.special_rule_manager.force_rules_every_round = (
		host.challenge_modifiers.force_special_rules_every_round
	)
	host.special_rule_manager.forced_rule_count = host.challenge_modifiers.forced_special_rule_count
	host.special_rule_manager.disable_rules_on_challenge_first_round = (
		host.current_challenge != null
		and host.challenge_modifiers.disable_special_rules_on_first_round
	)
	host.special_rule_manager.challenge_start_round = (
		host.current_challenge.start_round if host.current_challenge != null else 1
	)
	host.special_rule_manager.challenge_target_round = (
		host.current_challenge.target_round if host.current_challenge != null else 1
	)
	host.special_rule_manager.challenge_endless = host.challenge_endless
	host.game_mode = (
		host.GameMode.CHALLENGE
		if host.current_challenge != null
		else (host.GameMode.ENDLESS if endless_mode else host.GameMode.STANDARD)
	)
	host.soft_audio.play_start()
	host.music_manager.set_low_pass_enabled(false, true)
	host._hand_cycle_generation += 1
	host._pending_interactive_generation = -1
	host.pile_count = host.Difficulty.START_PILES
	host.hand_size = host.Difficulty.START_HAND_SIZE
	host.start_value = host.Difficulty.START_CARD_VALUE
	host.turn_time = host.Difficulty.START_TURN_TIME
	host.tier_reliefs_applied = 0
	host.difficulty_droughts = host._new_difficulty_droughts()
	host.run_mistake_count = 0
	host.run_lives_lost = 0
	host.run_completed_rounds = 0
	host.flawless_since_last_bonus = true
	host.started_from_checkpoint = false
	host.checkpoint_segment_damage_count = 0
	host.newly_discovered_bonuses.clear()
	host.newly_encountered_rules.clear()
	host.newly_unlocked_achievements.clear()
	host.newly_unlocked_fonts.clear()
	host.newly_unlocked_checkpoints.clear()
	host.current_checkpoint_id = 0
	host.checkpoint_bonus_backlog = 0
	host._pending_checkpoint_snapshot = null
	if host.game_mode == host.GameMode.CHALLENGE:
		host.round_number = (
			host.current_challenge.start_round
			if host.challenge_endless
			else host.current_challenge.target_round - host.current_challenge.start_round
		)
		host.run_start_round = host.current_challenge.start_round
		host.started_from_checkpoint = false
		host._apply_debug_progression(host.current_challenge.start_round)
		host._apply_challenge_starting_difficulty(host.current_challenge)
	elif host.game_mode == host.GameMode.ENDLESS:
		host.round_number = 1
		host.run_start_round = 1
	else:
		var debug_start_round := host.Debug.get_start_round(host.Difficulty.TOTAL_ROUNDS)
		host.started_from_checkpoint = debug_start_round > 1
		host.run_start_round = debug_start_round
		host.round_number = host.Difficulty.TOTAL_ROUNDS - debug_start_round + 1
		host._apply_debug_progression(debug_start_round)
	host._apply_seed_difficulty(sanitized_seed_difficulty)
	host.music_manager.reset_game_sections(host.tier_reliefs_applied + 1)
	host.background_manager.start_run(host.cosmetic_rng)
	host.music_manager.transition_to_game_music()
	host.game_started_msec = Time.get_ticks_msec()
	host.run_paused_msec = 0
	host.run_pause_started_msec = host.game_started_msec
	host.round_reached_time_ms = 0
	host.run_time_label.visible = host._global_timer_enabled
	host.overlay.visible = false
	host.quit_popup.visible = false
	host.overlay_mode = ""
	host.bonus_manager.begin_run()
	if not seed_bonus_levels.is_empty():
		host.bonus_manager.grant_starting_bonuses(seed_bonus_levels)
	if host.current_challenge != null:
		host.bonus_manager.grant_starting_bonuses(host.current_challenge.forced_bonuses)
	if animate_menu_exit:
		host._prepare_gameplay_start_reveal()
		host._update_hud()
		host._finish_animated_game_start()
	else:
		host.splash.visible = false
		host.start_round()


static func finish_animated_game_start(host: GameManager) -> void:
	await host._play_start_game_transition()
	host.start_round()


static func restart_current_mode(host: GameManager) -> void:
	if host._screen_transition_active:
		return
	host._screen_transition_active = true
	# Invalidate an in-flight round-completion coroutine immediately. The replay
	# iris is allowed to cover that transition instead of waiting for it to end.
	host._run_transition_generation += 1
	host._gameplay_generation += 1
	host._debug_round_wins_queued = 0
	host.input_locked = true
	host.timer_manager.stop_countdown()
	await host._mask_replay_transition()
	# Keep the popup visible during the iris close and remove it only while the
	# transition color fully covers the old run.
	host.bonus_selection.cancel()
	host.special_rule_manager.cancel_pending_round()
	host.quit_popup.visible = false
	await host.cleanup_special_rule_state(false)
	await host.special_rule_manager.end_round(host.piles, false)
	host._clear_gameplay_pieces_immediately()
	host._replay_board_ready = false
	host._restart_pile_reveal_pending = true
	host._restart_hand_immediate_pending = true
	host.special_rule_manager.suppress_next_announcement = true
	var preserve_run_seed := host.run_uses_requested_seed
	var replay_bonus_levels: Dictionary = {}
	var replay_rule_ids: Array[StringName] = []
	var replay_difficulty: Dictionary = {}
	if preserve_run_seed:
		replay_bonus_levels = host.run_seed_bonus_levels.duplicate()
		replay_rule_ids.assign(host.run_seed_rule_ids)
		replay_difficulty = host.run_seed_difficulty.duplicate()
	if host.game_mode == host.GameMode.CHECKPOINT:
		# A checkpoint replay is a fresh attempt: discard the old loadout and let
		# the player make the checkpoint's bonus choices again.
		host.start_from_checkpoint(
			host.current_checkpoint_id, {}, false,
			host.run_seed_label if preserve_run_seed else ""
		)
	elif host.game_mode == host.GameMode.CHALLENGE:
		host.start_game(
			false, host.current_challenge, host.challenge_endless,
			host.run_seed_label if preserve_run_seed else "",
			replay_bonus_levels, replay_rule_ids, replay_difficulty
		)
	else:
		host.start_game(
			host.game_mode == host.GameMode.ENDLESS, null, false,
			host.run_seed_label if preserve_run_seed else "",
			replay_bonus_levels, replay_rule_ids, replay_difficulty
		)
	# Special-rule cleanup (notably pixelation) is asynchronous. Keep the iris
	# shut until the replacement board exists instead of exposing stale effects.
	var ready_deadline := Time.get_ticks_msec() + 3000
	while (
		not host._replay_board_ready
		and not host.bonus_selection.visible
		and Time.get_ticks_msec() < ready_deadline
	):
		await host.get_tree().process_frame
	await host._unmask_replay_transition()
	host._screen_transition_active = false


static func return_to_menu(host: GameManager) -> void:
	if host._screen_transition_active:
		return
	host._screen_transition_active = true
	# Stop a round-completion coroutine that may currently be awaiting a bonus
	# choice; it must not resume behind the returning menu.
	host._run_transition_generation += 1
	host._gameplay_generation += 1
	host._debug_round_wins_queued = 0
	host.input_locked = true
	host.timer_manager.stop_countdown()
	host._splash_screen_index = host.splash.get_index()
	host.splash.reparent(host.menu_transition_layer, true)
	await host._play_return_to_menu_transition()
	# The raised menu now covers the popup completely, so hiding it cannot cut
	# the animation short.
	host.bonus_selection.cancel()
	host.special_rule_manager.cancel_pending_round()
	host.quit_popup.visible = false
	await host._reset_to_menu_state()
	host.splash.reparent(host.screens, true)
	host._restore_splash_screen_layout()
	if host._splash_screen_index >= 0:
		host.screens.move_child(host.splash, host._splash_screen_index)
	host._screen_transition_active = false


static func reset_to_menu_state(host: GameManager) -> void:
	# The raised Splash already presents the complete menu. Reset the run behind
	# it instead of reloading the scene, which would introduce a blank frame.
	host._conveyor_active = false
	host.bonus_selection.cancel()
	host.active_bonus_bar.visible = false
	host._hand_cycle_generation += 1
	host._pending_interactive_generation = -1
	await host.cleanup_special_rule_state()
	await host.special_rule_manager.end_round(host.piles)
	host.bonus_manager.end_run()
	host.hand_manager.clear_hand(host.hand_container)
	host._clear_drag_placeholder()
	for child in host.drag_layer.get_children():
		child.queue_free()
	for child in host.piles_board.get_children():
		child.queue_free()
	host.piles.clear()
	host.selected_card = null
	host.hovered_pile = null
	host.overlay.visible = false
	host.gameplay_layer.visible = false
	host.overlay_mode = ""
	host.back_button.visible = false
	host.run_time_label.visible = false
	host.music_manager.transition_to_menu_music()
	host._sync_shader_background_visibility()
	host._refresh_checkpoint_button()
	host._refresh_high_score()
	host._refresh_debug_help()


static func finish_game(host: GameManager, completed_all_rounds := false) -> void:
	host._end_gameplay_for_result_screen()
	host.music_manager.set_low_pass_enabled(true)
	var finite_victory := host._is_finite_mode_victory(completed_all_rounds)
	if finite_victory:
		host.soft_audio.play_victory()
		if host.game_mode == host.GameMode.STANDARD:
			host._unlock_endless_mode()
	else:
		host.soft_audio.play_game_over()
	# The death screen represents the whole run, including the round in which
	# the player died. `round_reached_time_ms` only tracks completed rounds.
	var score_time_ms := host._total_time_milliseconds()
	host.achievement_manager.run_completed.emit(
		host._build_run_summary(completed_all_rounds)
	)
	var formatted_time := host._format_duration(score_time_ms)
	var high_score_kind := ""
	match host.game_mode:
		host.GameMode.ENDLESS:
			high_score_kind = host._update_endless_high_score(host.round_number, score_time_ms)
		host.GameMode.CHECKPOINT:
			high_score_kind = host._update_checkpoint_high_score(host.round_number)
		host.GameMode.CHALLENGE:
			var challenge_high_score := host.challenge_manager.record_result(
				host.current_challenge,
				host._progression_round(),
				host.challenge_endless,
				score_time_ms,
				host.run_seed_value,
				host.run_seed_label
			)
			if challenge_high_score:
				high_score_kind = host.challenge_manager.last_record_kind
			if completed_all_rounds and not host.challenge_endless:
				host.achievement_manager.record_challenge_completion(
					host.current_challenge.id,
					host.challenge_manager.completed,
					host.challenge_manager.definitions
				)
		_:
			high_score_kind = host._update_high_score(host.round_number, score_time_ms)
	if host.game_mode != host.GameMode.CHALLENGE:
		host._update_no_mistake_high_score(host.round_number, score_time_ms)
	host.game_over.emit()
	host.overlay_unlocks.visible = false
	host.overlay_unlocks.text = ""
	host.overlay_high_score.visible = not high_score_kind.is_empty()
	if finite_victory:
		host.overlay_title.text = (
			"[center][color=#FFD700][wave amp=35.0 freq=4.0 connected=1]YOU WIN ![/wave][/color][/center]"
		)
		host.overlay_details.text = "[center]in %s[/center]" % formatted_time
	elif host.game_mode == host.GameMode.CHALLENGE and host.challenge_endless:
		host.overlay_title.text = "[center]%s[/center]" % host.current_challenge.title
		host.overlay_details.text = "[center]ENDLESS\nROUND %d\nin %s[/center]" % [
			host.round_number, formatted_time
		]
	elif host.game_mode == host.GameMode.CHALLENGE:
		var challenge_rounds_text := "%d ROUNDS LEFT" % maxi(host.round_number, 0)
		var challenge_time_text := "in %s" % formatted_time
		if high_score_kind == "ROUND":
			challenge_rounds_text = (
				"[color=#4D82C2]%s[/color]" % challenge_rounds_text
			)
		elif high_score_kind == "TIME":
			challenge_time_text = (
				"[color=#4D82C2]%s[/color]" % challenge_time_text
			)
		host.overlay_title.text = "[center]%s[/center]" % challenge_rounds_text
		host.overlay_details.text = "[center]%s[/center]" % challenge_time_text
	elif not high_score_kind.is_empty():
		var rounds_text := (
			host._checkpoint_result_text(host.round_number)
			if host.game_mode == host.GameMode.CHECKPOINT
			else (
				"ROUND %d" % host.round_number
				if host.game_mode == host.GameMode.ENDLESS
				else "%d ROUNDS LEFT" % host.round_number
			)
		)
		var time_text := (
			"CHECKPOINT RUN"
			if host.game_mode == host.GameMode.CHECKPOINT
			else "in %s" % formatted_time
		)
		if high_score_kind == "ROUND":
			rounds_text = "[color=#4D82C2]%s[/color]" % rounds_text
		else:
			time_text = "[color=#4D82C2]%s[/color]" % time_text
		host.overlay_title.text = "[center]%s[/center]" % rounds_text
		host.overlay_details.text = "[center]%s[/center]" % time_text
	elif host.game_mode == host.GameMode.ENDLESS:
		host.overlay_title.text = "[center]ROUND %d[/center]" % host.round_number
		host.overlay_details.text = "[center]in %s[/center]" % formatted_time
	elif host.game_mode == host.GameMode.CHECKPOINT:
		host.overlay_title.text = "[center]%s[/center]" % host._checkpoint_result_text(host.round_number)
		host.overlay_details.text = "[center]CHECKPOINT RUN[/center]"
	else:
		host.overlay_title.text = "[center]%d ROUNDS LEFT[/center]" % host.round_number
		host.overlay_details.text = "[center]in %s[/center]" % formatted_time
	host._append_new_progression_summary()
	host.end_seed_display.set_seed(host.run_seed_label)
	host.end_seed_display.set_copy_enabled(DisplayServer.has_feature(
		DisplayServer.FEATURE_CLIPBOARD
	))
	host.end_seed_display.visible = true
	host.overlay_button.text = "REPLAY"
	host.overlay_endless_button.visible = (
		completed_all_rounds
		and (
			host.game_mode == host.GameMode.STANDARD
			or (
				host.game_mode == host.GameMode.CHALLENGE
				and not host.challenge_endless
				and host.current_challenge.allow_endless
			)
		)
	)
	host.overlay_mode = "restart"
	host._show_game_over_overlay(not completed_all_rounds)
	# Cleanup can include rule-specific animations. Run it only after the result
	# is visible so the third mistake always produces immediate feedback.
	await host.cleanup_special_rule_state()
	await host.special_rule_manager.end_round(host.piles)


static func end_gameplay_for_result_screen(host: GameManager) -> void:
	# A result overlay is terminal for the current run. Invalidate every pending
	# gameplay continuation, including accelerated debug wins, before building
	# the screen so none can start a hand or apply delayed timeout damage behind it.
	host._run_transition_generation += 1
	host._gameplay_generation += 1
	host._hand_cycle_generation += 1
	host._debug_round_wins_queued = 0
	host._pending_interactive_generation = -1
	host._shared_clock_timeout_pending = false
	host._shared_clock_mistake_feedback_active = false
	host._quick_peek_pending = false
	host._preserve_timer_through_quick_peek = false
	host._conveyor_active = false
	host.input_locked = true
	host.timer_manager.stop_countdown()
	host.hand_manager.lock_hand()
	host.selected_card = null
	host.hovered_pile = null
	host.hand_manager.clear_selection()


static func is_finite_mode_victory(host: GameManager, completed_all_rounds: bool) -> bool:
	if not completed_all_rounds:
		return false
	return (
		host.game_mode == host.GameMode.STANDARD
		or (host.game_mode == host.GameMode.CHECKPOINT and not host.checkpoint_uses_endless_progression)
		or (host.game_mode == host.GameMode.CHALLENGE and not host.challenge_endless)
	)

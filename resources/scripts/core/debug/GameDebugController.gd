class_name GameDebugController
extends RefCounted

## Debug shortcuts, simulated progression and debug labels.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func handle_debug_shortcut(host: GameManager, event: InputEvent) -> bool:
	if not host.Debug.is_enabled() or not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	# The main menu only exposes debug actions that operate on menu/progression
	# state. Gameplay controls must not leak through the hidden board; notably R
	# must never restart a run from behind the Splash.
	if host.splash.visible and key_event.keycode not in [KEY_F1, KEY_U, KEY_H]:
		return false
	# Result screens and modal menus own their explicit shortcuts. Keep all
	# unrelated debug gameplay actions dormant while one of them is open.
	if (
		(host.overlay.visible or host.quit_popup.visible or host.progression_menu.visible
		or host.options_menu.visible or host.challenge_selection.visible
		or host.checkpoint_menu.visible)
		and key_event.keycode != KEY_F1
	):
		return false
	# Round wins are intentionally queueable so rapid debug presses can drive a
	# run through successive rounds while skipping transition animations.
	if key_event.keycode == KEY_E:
		if host.splash.visible or host.overlay.visible:
			return false
		host._debug_win_round()
		return true
	if host._debug_action_in_progress and key_event.keycode != KEY_R:
		return false
	match key_event.keycode:
		KEY_F1:
			host._debug_help_enabled = not host._debug_help_enabled
			return true
		KEY_U:
			host._toggle_debug_unlock_everything()
			return true
		KEY_S:
			if host.splash.visible or host.overlay.visible:
				return false
			host.music_manager.request_next_section()
			host._refresh_debug_help()
			return true
		KEY_B:
			if host.splash.visible or host.overlay.visible:
				return false
			host._debug_next_background()
			return true
		KEY_G:
			host.Debug.toggle_god_mode()
			host._refresh_debug_help()
			return true
		KEY_P:
			host._debug_probability_visible = not host._debug_probability_visible
			host.debug_probability_panel.visible = host._debug_probability_visible
			if host._debug_probability_visible:
				host.debug_probability_panel.text = host._difficulty_probability_debug_text()
			host._refresh_debug_help()
			return true
		KEY_V:
			host.relief_lighting.toggle_debug_boost()
			host._refresh_debug_help()
			return true
		KEY_R:
			host._debug_reset_game()
			return true
		KEY_H:
			host._debug_reset_progression()
			return true
		KEY_L:
			if host.splash.visible or host.overlay.visible or host.input_locked:
				return false
			host._debug_lose_life()
			return true
		KEY_K:
			if host.splash.visible or host.overlay.visible or host.input_locked:
				return false
			host._debug_die()
			return true
	return false


static func debug_win_round(host: GameManager) -> void:
	host._debug_round_wins_queued += 1
	# Debug round completion supersedes the current turn. Stop its timer before
	# raising time scale, otherwise it can expire during the few locked transition
	# frames and resolve as delayed damage in a later round.
	host.timer_manager.stop_countdown()
	host._shared_clock_timeout_pending = false
	if host.skippable_sequence.can_skip:
		host.skippable_sequence.skip_to_end()
	if host._debug_action_in_progress:
		return
	host._debug_action_in_progress = true
	var previous_time_scale := Engine.time_scale
	Engine.time_scale = maxf(previous_time_scale, 20.0)
	while host._debug_round_wins_queued > 0 and not host.splash.visible and not host.overlay.visible:
		host.timer_manager.stop_countdown()
		host._shared_clock_timeout_pending = false
		var transition_frames := 0
		while host.input_locked and not host.overlay.visible and transition_frames < 5:
			await host.get_tree().process_frame
			transition_frames += 1
		if host.overlay.visible:
			break
		# A queued debug win deliberately supersedes any remaining transition.
		host.input_locked = false
		host._debug_round_wins_queued -= 1
		await host._finish_round()
	host._debug_round_wins_queued = 0
	Engine.time_scale = previous_time_scale
	host._debug_action_in_progress = false


static func debug_lose_life(host: GameManager) -> void:
	host._debug_action_in_progress = true
	await host._handle_mistake(null, false, true)
	host._debug_action_in_progress = false


static func debug_die(host: GameManager) -> void:
	host._debug_action_in_progress = true
	# Use the regular mistake pipeline so audio, counters, discoveries and the
	# game-over transition remain representative of a real run.
	host.mistakes_left = 1
	await host._handle_mistake(null, false, true)
	host._debug_action_in_progress = false


static func debug_next_background(host: GameManager) -> void:
	if not host._background_enabled or not is_instance_valid(host.background_manager):
		return
	host.background_manager.transition_to_next(host.cosmetic_rng)
	if host.Debug.DISABLE_BG_MORPH_TRANSITION:
		host.background_manager.skip_transition()
	host._refresh_debug_help()


static func debug_reset_game(host: GameManager) -> void:
	host._debug_action_in_progress = true
	await host._restart_current_mode()
	host._debug_action_in_progress = false


static func debug_reset_progression(host: GameManager) -> void:
	host.best_rounds_left = -1
	host.best_score_time_ms = -1
	host.classic_no_mistake_rounds_left = -1
	host.classic_no_mistake_time_ms = -1
	host.endless_best_round = -1
	host.endless_best_time_ms = -1
	host.endless_no_mistake_round = -1
	host.endless_unlocked = false
	host.unlocked_checkpoints.clear()
	host.checkpoint_snapshots.clear()
	host.checkpoint_highscores.clear()
	host.checkpoint_no_mistake_highscores.clear()
	host.checkpoint_best_round = -1
	host.checkpoint_no_mistake_best_round = -1
	host.checkpoint_best_rounds_left = -1
	host.checkpoint_endless_best_round = -1
	host.checkpoint_no_mistake_rounds_left = -1
	host.checkpoint_endless_no_mistake_round = -1
	host.current_checkpoint_id = 0
	host.checkpoint_bonus_backlog = 0
	host.selected_checkpoint_id = 0
	host.discovered_bonuses.clear()
	host.max_discovered_tile_value = host.Difficulty.START_CARD_VALUE
	host.max_discovered_pile_count = host.Difficulty.START_PILES
	host.max_discovered_hand_size = host.Difficulty.START_HAND_SIZE
	host.min_discovered_turn_time = host.Difficulty.START_TURN_TIME
	host.seen_bonuses.clear()
	host.encountered_special_rules.clear()
	host.beaten_special_rules.clear()
	host.challenge_manager.debug_unlock_all = false
	host.challenge_manager.completed.clear()
	host.challenge_manager.highscores.clear()
	host.challenge_manager.endless_highscores.clear()
	host.challenge_manager.best_times_ms.clear()
	host.achievement_manager.unlocked.clear()
	host.achievement_manager.unlock_dates.clear()
	host.achievement_manager.bonuses_maxed_once.clear()
	host.achievement_manager.bonus_highest_levels.clear()
	host.font_manager.unlocked.clear()
	for font_data in host.font_manager.definitions:
		if font_data.default_unlocked:
			host.font_manager.unlocked.append(font_data.id)
	var default_font := host.progression_menu.get_default_font()
	host.font_manager.selected_font = (
		default_font.id if default_font != null else &"press_start_2p"
	)
	host.font_manager.select(host.font_manager.selected_font)
	host.palette_manager.unlocked.clear()
	for palette_data in host.palette_manager.definitions:
		if palette_data.default_unlocked:
			host.palette_manager.unlocked.append(palette_data.id)
	var default_palette := host.progression_menu.get_default_palette()
	host.palette_manager.selected_palette = (
		default_palette.id if default_palette != null else &"arcade"
	)
	host.palette_manager.select(host.palette_manager.selected_palette)
	host._apply_tile_font()
	host._apply_tile_palette()
	var config := ConfigFile.new()
	if config.load(SaveConfig.PATH) == OK:
		# Whole sections are removed so achievements and progression fields added
		# in future versions are reset without extending this debug command.
		for section in [
			"progress", "highscores", "checkpoints", "progression", "challenges"
		]:
			if config.has_section(section):
				config.erase_section(section)
		if config.has_section_key("settings", "selected_font"):
			config.erase_section_key("settings", "selected_font")
		if config.has_section_key("settings", "selected_palette"):
			config.erase_section_key("settings", "selected_palette")
		config.save(SaveConfig.PATH)
	host.endless_unlocked = host.Debug.unlock_endless_mode()
	host.endless_button.visible = host.endless_unlocked
	host._refresh_checkpoint_button()
	host._refresh_high_score()


static func refresh_debug_help(host: GameManager) -> void:
	if not host.Debug.is_enabled():
		host.debug_help.visible = false
		host.splash_debug_help.visible = false
		return
	var full_help_text := (
		"[U] TOGGLE UNLOCK EVERYTHING\n"
		+ "[E] WIN CURRENT ROUND\n"
		+ "[S] NEXT MUSIC SECTION\n"
		+ "[B] NEXT BACKGROUND\n"
		+ "[G] GOD MODE: %s\n" % ("ON" if host.Debug.is_god_mode_enabled() else "OFF")
		+ "[R] RESET GAME\n"
		+ "[H] CLEAR GLOBAL PROGRESSION\n"
		+ "[L] LOSE ONE LIFE\n"
		+ "[K] DIE NOW\n"
		+ "[P] DIFFICULTY PROBABILITIES: %s\n" % (
			"ON" if host._debug_probability_visible else "OFF"
		)
		+ "[V] RELIEF LIGHT BOOST: %s\n" % (
			"ON" if host.relief_lighting.debug_boosted else "OFF"
		)
		+ "[T] SHOW RUN TIME\n"
		+ "[M] MUTE AUDIO\n"
		+ "[F1] HIDE DEBUG HELP\n"
		+ "[ESC] BACK TO MENU"
	)
	var collapsed_help_text := "DEBUG SHORTCUTS\nHOVER TO OPEN  F1 HIDE"
	var help_text := full_help_text if host._debug_help_expanded else collapsed_help_text
	host.debug_help.text = help_text
	host.splash_debug_help.text = help_text
	host._fit_debug_help(host.debug_help, false)
	host._fit_debug_help(host.splash_debug_help, true)
	host.splash_debug_help.visible = host._debug_help_enabled and host.splash.visible


static func on_debug_help_mouse_entered(host: GameManager) -> void:
	host._set_debug_help_expanded(true)


static func on_debug_help_mouse_exited(host: GameManager) -> void:
	host._set_debug_help_expanded(false)


static func set_debug_help_expanded(host: GameManager, expanded: bool) -> void:
	if host._debug_help_expanded == expanded:
		return
	host._debug_help_expanded = expanded
	host._refresh_debug_help()


static func fit_debug_help(host: GameManager, label: Label, on_splash: bool) -> void:
	var line_count := label.text.count("\n") + 1
	var line_height := 7.0 if on_splash else 9.0
	var bottom := -8.0 if on_splash else -4.0
	var height := maxf(16.0, line_count * line_height + 4.0)
	label.offset_top = bottom - height
	label.offset_bottom = bottom
	label.offset_right = label.offset_left + (166.0 if host._debug_help_expanded else 150.0)


static func difficulty_probability_debug_text(host: GameManager) -> String:
	return host.difficulty_progression.probability_debug_text(host._progression_round())


static func toggle_debug_unlock_everything(host: GameManager) -> void:
	host.Debug.toggle_unlock_everything()
	host.get_tree().reload_current_scene()


static func apply_debug_unlock_everything(host: GameManager) -> void:
	if not host.Debug.is_unlock_everything_enabled():
		return
	host.challenge_manager.debug_unlock_all = true
	host.max_discovered_tile_value = host.Difficulty.MAX_CARD_VALUE
	host.max_discovered_pile_count = host.Difficulty.MAX_PILES
	host.max_discovered_hand_size = host.Difficulty.MAX_HAND_SIZE
	host.min_discovered_turn_time = host.Difficulty.MIN_TURN_TIME
	host.achievement_manager.unlocked.clear()
	for achievement in host.achievement_manager.definitions:
		host.achievement_manager.unlocked.append(achievement.id)
	host.font_manager.unlocked.clear()
	for font_data in host.font_manager.definitions:
		host.font_manager.unlocked.append(font_data.id)
	host.palette_manager.unlocked.clear()
	for palette_data in host.palette_manager.definitions:
		host.palette_manager.unlocked.append(palette_data.id)
	host.discovered_bonuses.clear()
	host.seen_bonuses.clear()
	for bonus_data in BonusRegistry.create_all():
		host.discovered_bonuses.append(bonus_data.id)
		host.seen_bonuses.append(bonus_data.id)
		host.achievement_manager.bonus_highest_levels[bonus_data.id] = bonus_data.max_level
		host.achievement_manager.bonuses_maxed_once[bonus_data.id] = true
	host.encountered_special_rules.clear()
	host.beaten_special_rules.clear()
	for rule_data in SpecialRuleRegistry.create_all_rules():
		host.encountered_special_rules.append(rule_data.id)
		host.beaten_special_rules.append(rule_data.id)
	host.challenge_manager.completed.clear()
	for challenge_data in host.challenge_manager.definitions:
		host.challenge_manager.completed.append(challenge_data.id)

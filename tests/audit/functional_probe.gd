extends SceneTree

## Diagnostic only: invoked by run_audit.py with an isolated user:// profile.
## Public handlers drive normal actions; injected boundary states are named in observations.
const MAIN := preload("res://resources/scenes/Main.tscn")
var main: Control
var game: GameManager
var scenario := ""
var detail := ""
var observations: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func record(name: String, observed: Variant, expected: Variant = null) -> void:
	var entry := {"name": name, "observed": observed}
	if expected != null:
		entry["expected"] = expected
		entry["matches"] = observed == expected
	observations.append(entry)
	print("AUDIT " + JSON.stringify(entry))


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("audit-profiles/"):
		push_error("Refusing audit without isolated audit-profiles directory")
		quit(2)
		return
	var args := OS.get_cmdline_user_args()
	scenario = args[0] if args.size() > 0 else "matrix"
	detail = args[1] if args.size() > 1 else "standard"
	root.size = Vector2i(512, 640)
	if scenario == "save":
		await save_probe()
	elif scenario == "bonus_cancel":
		await boot()
		await bonus_cancel_probe()
	else:
		await boot()
		match scenario:
			"matrix": await matrix_probe()
			"race": await race_probe()
			"seed_history": await seed_history_probe()
			"progression": await progression_probe()
			"ui": await ui_probe()
			"damage": await damage_probe()
			"seed_input": await seed_input_probe()
			"touch_mirror": await touch_mirror_probe()
			"bonus_integration": await bonus_integration_probe()
			"seed_rule_restart": await seed_rule_restart_probe()
			"limits": await limits_probe()
			"seed_ui": await seed_ui_probe()
			"bonus_choice": await bonus_choice_probe()
	if is_instance_valid(main):
		main.queue_free()
		await process_frame
	print("AUDIT_DONE " + JSON.stringify({"scenario": scenario, "detail": detail, "observations": observations.size()}))
	quit()


func boot() -> void:
	main = MAIN.instantiate() as Control
	root.add_child(main)
	for frame in 5:
		await process_frame
	game = main.get_node("GameCenter/Game") as GameManager
	record("menu_visible", game.splash.visible, true)


func wait_ready(seconds := 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if game.overlay.visible:
			return false
		if game.skippable_sequence.can_skip:
			game.skippable_sequence.skip_to_end()
		if not game.input_locked and not game._screen_transition_active:
			return true
		await process_frame
	return false


func start(data: ChallengeData = null, seed_text := "AUDIT-2026", bonuses: Dictionary = {}) -> bool:
	game.splash.hide()
	game.start_game(false, data, false, seed_text, bonuses)
	var ready := await wait_ready()
	record("run_ready", ready, true)
	return ready


func signature() -> Dictionary:
	var hand: Array[int] = []
	for card in game.hand_manager.active_cards():
		hand.append(card.card_value)
	var rules: Array[StringName] = []
	for rule in game.special_rule_manager.active_rules:
		rules.append(rule.id)
	return {"piles": game.pile_count, "hand_size": game.hand_size,
		"value": game.start_value, "timer": game.turn_time,
		"cards": hand, "rules": rules, "seed": game.run_seed_label}


func challenge(id: String) -> ChallengeData:
	for path in DirAccess.get_files_at("res://resources/data/challenges"):
		if path.ends_with(".tres"):
			var data := load("res://resources/data/challenges/" + path) as ChallengeData
			if String(data.id) == id:
				return data
	return null


func solve_round() -> bool:
	var initial := game.run_completed_rounds
	var deadline := Time.get_ticks_msec() + 45000
	var last_action := 0
	while game.run_completed_rounds == initial and Time.get_ticks_msec() < deadline:
		if game.overlay.visible:
			return false
		if not game.input_locked and Time.get_ticks_msec() - last_action > 70:
			var played := false
			for card in game.hand_manager.active_cards():
				if card._entrance_animation_running:
					continue
				for pile in game.piles:
					if not pile.completed and (card.is_joker or pile.can_accept(card.card_value)):
						game._on_card_selected(card)
						game._on_card_drag_started(card, true)
						game._on_card_drag_released(card, pile.get_global_transform() * (pile.size * 0.5))
						played = true
						break
				if played:
					break
			if not played and game.current_challenge != null and game.current_challenge.id == &"reload_required":
				game._on_redraw_pressed()
			last_action = Time.get_ticks_msec()
		await process_frame
	return game.run_completed_rounds > initial


func matrix_probe() -> void:
	var data := challenge(detail)
	var bonuses := {&"safety_net": 1, &"redraw": 1}
	if data != null:
		for id in data.disabled_bonuses:
			bonuses.erase(id)
	if not await start(data, "AUDIT-2026", bonuses):
		return
	record("challenge", String(game.current_challenge.id) if data != null else "standard")
	record("initial", signature())
	record("lives", game.maximum_mistakes, 1 if data != null and data.force_single_life else 3)
	record("bonus_levels", game.bonus_manager.active_levels())
	var initial := signature()
	game._open_quit_popup()
	record("pause_seed", game.pause_seed_display.seed_text if "seed_text" in game.pause_seed_display else game.run_seed_label)
	var clock := game.timer_manager.time_left
	await create_timer(0.12).timeout
	record("popup_keeps_clock_running_by_design", game.timer_manager.time_left < clock, true)
	game._close_quit_popup()
	game._restart_current_mode()
	game._restart_current_mode()
	record("restart_ready", await wait_ready(), true)
	record("restart_initial_state", signature(), initial)
	record("first_round_solved", await solve_round(), true)
	await wait_ready()
	record("next_round_number", game._progression_round(), data.start_round + 1 if data != null else 2)
	record("next_round_rules", signature().rules)
	# Boundary injection: test the final-round transition without fast-forwarding its RNG.
	game.round_number = 1
	for pile in game.piles:
		pile.current_value = 0
		pile.completed = true
	game._finish_round()
	var deadline := Time.get_ticks_msec() + 8000
	while not game.overlay.visible and Time.get_ticks_msec() < deadline:
		if game.skippable_sequence.can_skip:
			game.skippable_sequence.skip_to_end()
		await process_frame
	record("injected_final_round_victory", game.overlay.visible and game.overlay_title.text.contains("YOU WIN"), true)
	await create_timer(0.3).timeout
	game._on_overlay_endless_pressed()
	record("endless_ready", await wait_ready(), true)
	record("endless_mode", game.challenge_endless if data != null else game.game_mode == GameManager.GameMode.ENDLESS, true)
	record("endless_seed", game.run_seed_label, "AUDIT-2026")
	await game._return_to_menu()
	record("return_menu", game.splash.visible and not game.gameplay_layer.visible, true)
	await start()
	record("new_standard_cleans_challenge", game.current_challenge == null and not game.challenge_modifiers.conveyor_hand and not game.challenge_modifiers.shared_round_clock and not game.challenge_modifiers.force_single_life, true)
	record("new_standard_cleans_bonuses", game.bonus_manager.active.is_empty(), true)


func race_probe() -> void:
	await start(null, "AUDIT-RACE", {&"redraw": 2, &"safety_net": 1})
	match detail:
		"damage_menu", "damage_restart":
			game.mistakes_left = 1
			game.bonus_manager.safety_net_available = false
			game._handle_mistake()
			await create_timer(0.02).timeout
		"reload_menu", "reload_restart":
			game._on_redraw_pressed()
			await create_timer(0.02).timeout
		"placement_restart", "placement_menu":
			var card := game.hand_manager.active_cards()[0]
			while card._entrance_animation_running: await process_frame
			game._on_card_selected(card)
			game._on_card_drag_started(card, true)
			game._on_card_drag_released(card, game.piles[0].get_global_transform() * (game.piles[0].size * 0.5))
			await create_timer(0.02).timeout
		"start_double":
			await game._return_to_menu()
			game._on_splash_pressed()
			game._on_splash_pressed()
			record("double_start_ready", await wait_ready(), true)
			record("double_start_live_piles", game.piles_board.get_child_count(), game.pile_count)
			return
	game._open_quit_popup()
	if detail.ends_with("menu"):
		await game._return_to_menu()
		await create_timer(1.2).timeout
		record("after_race_menu", {"menu": game.splash.visible, "overlay": game.overlay.visible, "timer": game.timer_manager.running, "cards": game.hand_manager.active_cards().size(), "popup": game.quit_popup.visible})
		await start(null, "AUDIT-AFTER-RACE")
	else:
		await game._restart_current_mode()
		await wait_ready()
	await create_timer(1.2).timeout
	record("after_race_playable", not game.input_locked and not game.overlay.visible and not game.splash.visible, true)
	record("after_race_state", {"piles": game.piles.size(), "nodes": game.piles_board.get_child_count(), "lives": game.mistakes_left, "cards": game.hand_manager.active_cards().size(), "seed": game.run_seed_label, "overlay": game.overlay.visible, "title": game.overlay_title.text, "locked": game.input_locked, "menu": game.splash.visible})


func seed_history_probe() -> void:
	await start(null, detail)
	var first: Array[Dictionary] = []
	var second: Array[Dictionary] = []
	for attempt in 2:
		if attempt > 0:
			await game._restart_current_mode()
			await wait_ready()
		for round_index in range(1, 9):
			var snapshot := signature()
			if attempt == 0: first.append(snapshot)
			else: second.append(snapshot)
			record("seed_round_%d_%d" % [attempt, round_index], snapshot)
			if round_index == 8: break
			if not await solve_round():
				record("seed_solver_stopped", round_index)
				return
			await settle_round()
		record("run_complete_signature_count", first.size() if attempt == 0 else second.size())
	record("same_seed_eight_rounds", second, first)


func seed_rule_restart_probe() -> void:
	await start(null, detail)
	var first: Dictionary = {}
	for attempt in 2:
		if attempt > 0:
			await game._restart_current_mode()
			await wait_ready()
		for round_index in 3:
			if not await solve_round():
				record("seed_solver_stopped", round_index)
				return
			await settle_round()
		if attempt == 0:
			first = signature()
			record("first_round_four", first)
		else:
			record("replayed_round_four", signature(), first)


func limits_probe() -> void:
	var bonuses := {}
	for data in BonusRegistry.create_all(): bonuses[data.id] = data.max_level
	game.splash.hide()
	game.start_game(false, null, false, "AUDIT-MAX", bonuses, [], {"pile_count": 999, "hand_size": 999, "start_value": 999, "turn_time": -1.0})
	await wait_ready()
	record("maximum_sanitized", signature())
	record("maximum_bonus_count", game.bonus_manager.active.size(), BonusRegistry.create_all().size())
	record("maximum_lives", game.maximum_mistakes)
	record("maximum_redraws", game.bonus_manager.redraws_left)
	game.bonus_manager.redraws_left = 0
	var before := signature()
	game._on_redraw_pressed()
	await create_timer(0.1).timeout
	record("zero_reload_no_hand_change", signature(), before)
	game._open_quit_popup()
	for index in 20:
		game._close_quit_popup()
		game._open_quit_popup()
	game._close_quit_popup()
	record("popup_spam_recovered", not game.quit_popup.visible, true)
	await game._return_to_menu()
	await start()
	record("maximum_bonus_reset", game.bonus_manager.active.is_empty(), true)


func settle_round() -> bool:
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		if game.skippable_sequence.can_skip:
			game.skippable_sequence.skip_to_end()
		if game.bonus_selection.visible and game.bonus_selection.skip_button.visible:
			game.bonus_selection._skip()
		if not game.input_locked and not game._screen_transition_active:
			return true
		if game.overlay.visible: return false
		await process_frame
	return false


func progression_probe() -> void:
	await start(null, "AUDIT-LONG", {&"safety_net": 1, &"redraw": 2})
	for step in 30:
		# Boundary injection tests sequencing, not the ability to solve each late board.
		for pile in game.piles:
			pile.current_value = 0
			pile.completed = true
		game._finish_round()
		await settle_round()
		record("progress_step", {"step": step + 1, "round": game._progression_round(), "tier": game.tier_reliefs_applied, "background": game.background_manager.last_background_id, "lives": game.maximum_mistakes, "overlay": game.overlay.visible, "locked": game.input_locked})
		if game.overlay.visible: break
	record("thirty_round_victory", game.overlay_title.text.contains("YOU WIN"), true)


func damage_probe() -> void:
	await start(challenge(detail), "AUDIT-DAMAGE", {&"safety_net": 1, &"redraw": 2})
	var initial_lives := game.mistakes_left
	game._handle_mistake()
	await wait_ready()
	record("safety_net_life_preserved", game.mistakes_left, initial_lives if detail != "one_shot" else 0)
	record("damage_breaks_flawless", game.flawless_since_last_bonus, false)
	if game.overlay.visible: return
	var lives := game.mistakes_left
	game.flawless_since_last_bonus = true
	game._on_redraw_pressed()
	await wait_ready()
	record("reload_keeps_lives", game.mistakes_left, lives)
	record("reload_keeps_flawless", game.flawless_since_last_bonus, true)
	record("reload_remaining", game.bonus_manager.redraws_left)
	game.mistakes_left = 1
	game.timer_manager.time_left = 0.001
	await create_timer(2.0).timeout
	record("last_life_timeout_game_over", game.overlay.visible, true)
	record("zero_life_terminal", game.input_locked and not game.timer_manager.running, true)


func bonus_cancel_probe() -> void:
	var definitions := BonusRegistry.create_all()
	var choices: Array[BonusData] = [definitions[0], definitions[1], definitions[2]]
	var levels: Array[int] = [1, 1, 1]
	game.bonus_selection.present(choices, levels, true)
	await create_timer(0.04).timeout
	game.bonus_selection.cancel()
	await create_timer(0.65).timeout
	record("cancelled_flawless_stays_hidden", game.bonus_selection.visible, false)
	record("cancelled_flawless_mode", game.bonus_selection._presentation_mode, 0)


func bonus_choice_probe() -> void:
	await start(null, "AUDIT-BONUS")
	game.timer_manager.stop_countdown()
	game.input_locked = true
	for index in 2:
		game.bonus_manager.offer_if_due(4 * (index + 1), 2 + index, index == 1)
		await create_timer(0.65).timeout
		var visible_choices := 0
		for button in game.bonus_selection._bonus_buttons:
			if button.visible: visible_choices += 1
		record("choice_count", visible_choices, 2 + index)
		game.bonus_selection._bonus_buttons[0].pressed.emit()
		await create_timer(0.35).timeout
		var level_sum := 0
		for level in game.bonus_manager.active_levels().values(): level_sum += int(level)
		record("choice_granted_once", level_sum, index + 1)
		record("choice_closed", game.bonus_selection.visible, false)
	var maximum := {}
	for data in BonusRegistry.create_all(): maximum[data.id] = data.max_level
	game.bonus_manager.grant_starting_bonuses(maximum)
	record("max_bonus_offer_returns", await game.bonus_manager.offer_if_due(12), false)


func bonus_integration_probe() -> void:
	await start(null, "AUDIT-FLAWLESS")
	var definitions := BonusRegistry.create_all()
	var choices: Array[BonusData] = [definitions[0], definitions[1], definitions[2]]
	var levels: Array[int] = [1, 1, 1]
	game.bonus_selection.present(choices, levels, true)
	await create_timer(0.02).timeout
	game._open_quit_popup()
	await game._restart_current_mode()
	await wait_ready()
	await create_timer(0.7).timeout
	record("restart_flawless_visibility", game.bonus_selection.visible, false)
	record("restart_flawless_mode", game.bonus_selection._presentation_mode, 0)


func touch_mirror_probe() -> void:
	await start(null, "AUDIT-MIRROR")
	var modifiers := RoundModifiers.new()
	modifiers.mirror_vertical = true
	game.mirror_match_controller.end_round(game)
	game.mirror_match_controller.begin_round(game, modifiers)
	await process_frame
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = game.back_button.get_global_transform() * (game.back_button.size * 0.5)
	record("mirrored_back_rect", str(game.back_button.get_global_rect()))
	record("mirrored_back_detected", game._is_gameplay_back_pointer_event(press), true)
	var mouse_press := InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.pressed = true
	mouse_press.position = press.position
	record("mirrored_back_mouse_detected", game._is_gameplay_back_pointer_event(mouse_press), true)
	mouse_press.position = game.back_button.get_global_transform_with_canvas() * Vector2(-10, -10)
	record("mirrored_back_outside_rejected", game._is_gameplay_back_pointer_event(mouse_press), false)
	var motion := InputEventMouseMotion.new()
	motion.position = press.position
	game._update_gameplay_back_hover(motion)
	game._input(press)
	record("mirrored_back_opens_popup_via_input", game.quit_popup.visible, true)


func ui_probe() -> void:
	await start(null, "AUDIT-UI")
	game.bonus_manager.grant_starting_bonuses({&"deja_vu": 1})
	await process_frame
	for pixel_art in [false, true]:
		game._true_pixel_art_enabled = pixel_art
		for mode in [&"classic", &"semi_adaptive", &"adaptive"]:
			game._screen_size_mode = mode
			GameOptionsController.apply_resolution(game)
			for window_size in [Vector2i(512, 640), Vector2i(1068, 1808), Vector2i(1908, 968)]:
				root.size = window_size
				for frame in 8: await process_frame
				game._open_quit_popup()
				for frame in 3: await process_frame
				record("pause_layout", {"mode": mode, "pixel": pixel_art, "window": str(window_size), "contained": game.quit_popup.get_global_rect().encloses(game.quit_panel.get_global_rect())})
				game._close_quit_popup()
				var current_badge := game.active_bonus_bar.get_child(0) as ActiveBonusBadge
				current_badge.description_requested.emit(BonusRegistry.get_bonus(&"deja_vu").description)
				for frame in 3: await process_frame
				record("tooltip_layout", {"mode": mode, "pixel": pixel_art, "window": str(window_size), "rect": str(game.bonus_manager.active_description.get_global_rect()), "viewport": str(game.get_viewport_rect()), "contained": game.get_viewport_rect().encloses(game.bonus_manager.active_description.get_global_rect())})
				current_badge.description_hidden.emit()
	game.bonus_manager.grant_starting_bonuses({&"deja_vu": 1})
	await process_frame
	var badge := game.active_bonus_bar.get_child(0) as ActiveBonusBadge
	badge.description_requested.emit(BonusRegistry.get_bonus(&"deja_vu").description)
	for frame in 5: await process_frame
	record("tooltip_rect", str(game.bonus_manager.active_description.get_global_rect()))
	record("tooltip_contained", game.get_viewport_rect().encloses(game.bonus_manager.active_description.get_global_rect()), true)


func seed_input_probe() -> void:
	for seed_text in ["0", "-9223372036854775808", "9223372036854775807", "9223372036854775808", "  AUDIT TEXT  ", ""]:
		await start(null, seed_text)
		record("seed_parse", {"input": seed_text, "label": game.run_seed_label, "value": str(game.run_seed_value), "requested": game.run_uses_requested_seed})
		await game._return_to_menu()
	game.splash.hide()
	game.start_game(false, null, false, "AUDIT-CUSTOM", {}, [], {"pile_count": 2, "hand_size": 2, "start_value": 2, "turn_time": 4.0})
	await wait_ready()
	var custom := game.run_seed_difficulty.duplicate()
	await game._finish_game(true)
	game._on_overlay_endless_pressed()
	await wait_ready()
	record("custom_difficulty_survives_endless", game.run_seed_difficulty, custom)
	await game._return_to_menu()
	var challenge := game.challenge_manager.definitions[0]
	game.splash.hide()
	game.start_game(false, challenge, false, "AUDIT-CUSTOM", {}, [], custom)
	await wait_ready()
	await game._finish_game(true)
	game._on_overlay_endless_pressed()
	await wait_ready()
	record("challenge_custom_difficulty_survives_endless", game.run_seed_difficulty, custom)


func save_probe() -> void:
	var config := ConfigFile.new()
	match detail:
		"missing": pass
		"old":
			config.set_value("progress", "best_time_ms", 12345)
			config.save(SaveConfig.PATH)
		"incomplete":
			config.set_value("settings", "selected_font", "missing-font-id")
			config.save(SaveConfig.PATH)
		"wrong_types":
			config.set_value("challenges", "highscores", "not a dictionary")
			config.save(SaveConfig.PATH)
		"import_wrong_types":
			config.set_value("audit", "preserved", 42)
			config.save(SaveConfig.PATH)
			var manager := SaveDataManager.new()
			var file := FileAccess.open("user://malformed.json", FileAccess.WRITE)
			file.store_string(JSON.stringify({"format": "pile-down-save", "version": 1, "sections": JSON.from_native({"challenges": {"highscores": "not a dictionary"}})}))
			file.close()
			record("malformed_import_result", manager.import_json("user://malformed.json"), ERR_INVALID_DATA)
			config.load(SaveConfig.PATH)
			record("rejected_import_preserves_save", config.get_value("audit", "preserved", 0), 42)
			manager.free()
	await boot()
	if detail == "persist_write":
		var data := game.challenge_manager.definitions[0]
		game.challenge_manager.record_result(data, data.target_round, false, 12345, 42, "AUDIT-PERSIST")
		game.achievement_manager.unlock(game.achievement_manager.definitions[0].id)
		game._save_gameplay_option("show_timer", false)
		game.best_score_time_ms = 12345
		game._save_high_score()
		record("persist_written_challenge", String(data.id))
	if detail == "persist_read":
		var data := game.challenge_manager.definitions[0]
		record("persist_completed_challenge", game.challenge_manager.completed.has(data.id), true)
		record("persist_challenge_time", game.challenge_manager.best_times_ms.get(data.id), 12345)
		record("persist_challenge_seed", game.challenge_manager.record_seeds.get(data.id))
		record("persist_achievement", game.achievement_manager.unlocked.has(game.achievement_manager.definitions[0].id), true)
		record("persist_option", game._global_timer_enabled, false)
	record("save_boot_menu", game.splash.visible, true)
	record("save_loaded_best_time", game.best_score_time_ms)
	record("save_loaded_font", game.font_manager.selected_font)


func seed_ui_probe() -> void:
	game._open_challenge_selection()
	await create_timer(0.3).timeout
	game.challenge_selection._seed_input.text = "  AUDIT-FROM-MENU  "
	game.challenge_selection._seed_mode.select(0)
	game.challenge_selection._play_seed()
	await wait_ready()
	record("menu_seed_is_used", game.run_seed_label, "AUDIT-FROM-MENU")
	game._open_quit_popup()
	record("menu_seed_is_displayed", game.pause_seed_display.seed_text, game.run_seed_label)

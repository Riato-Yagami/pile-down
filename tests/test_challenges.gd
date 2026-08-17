extends SceneTree

const GAME_SCENE := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager := ChallengeManager.new()
	assert(manager.definitions.size() >= 8)
	var reload := manager.find(&"reload_required")
	var one_shot := manager.find(&"one_shot")
	var pool_party := manager.find(&"pool_party")
	var true_colors := manager.find(&"true_colors")
	for challenge in manager.definitions:
		assert(challenge.resource_path.begins_with(
			"res://resources/data/challenges/"
		))
		assert(challenge.required_achievement != null)
		assert(not challenge.required_achievement_id().is_empty())
	assert(reload.start_round >= 1 and reload.target_round > reload.start_round)
	assert(not manager.modifiers_for(reload).guarantee_playable_hand)
	assert(is_equal_approx(manager.modifiers_for(reload).reload_low_time_bonus, 2.0))
	assert(manager.modifiers_for(one_shot).force_single_life)
	assert(manager.modifiers_for(pool_party).pool_physics_enabled)
	assert(manager.modifiers_for(true_colors).hide_tile_numbers)
	assert(manager.modifiers_for(reload).disable_special_rules_on_first_round)
	assert(true_colors.disabled_rules.has(&"colorblind"))
	var configured := ChallengeData.new()
	configured.start_round = 12
	configured.starting_pile_count = 3
	configured.starting_hand_size = 4
	configured.starting_card_value = 7
	configured.starting_turn_time = 8.5
	configured.forced_bonuses = {&"redraw": 2}
	assert(not manager.is_unlocked(reload, []))
	assert(manager.is_unlocked(reload, [&"full_magazine"]))
	assert(manager.record_result(reload, reload.start_round + 2, false, 1800))
	assert(manager.highscores[reload.id] == reload.start_round + 2)
	assert(manager.best_times_ms[reload.id] == 1800)
	assert(manager.last_record_kind == "ROUND")
	assert(manager.record_result(reload, reload.start_round + 2, false, 1700))
	assert(manager.last_record_kind == "TIME")
	assert(not manager.record_result(reload, reload.start_round + 1, false, 1700))
	assert(manager.record_result(reload, reload.target_round, false, 2500))
	assert(manager.completed.has(reload.id))
	assert(manager.best_times_ms[reload.id] == 2500)
	assert(not manager.record_result(reload, reload.target_round, false, 3000))
	assert(manager.best_times_ms[reload.id] == 2500)
	assert(manager.record_result(reload, reload.target_round, false, 2000))
	assert(manager.best_times_ms[reload.id] == 2000)

	var game := GAME_SCENE.instantiate() as GameManager
	root.add_child(game)
	game.achievement_manager.unlocked.assign([
		&"full_magazine", &"overprotected",
		&"bring_a_friend_full_activation", &"colorblind_expert",
	])
	game._open_challenge_selection()
	assert(game.challenge_selection.visible)
	assert(
		game.challenge_selection.list.get_child_count()
		== game.challenge_manager.definitions.size()
	)
	game.challenge_selection.close()
	await create_timer(game.submenu_swipe_duration + 0.05).timeout
	assert(not game.challenge_selection.visible)

	game.splash.visible = false
	game.start_game(false, reload, false)
	assert(game.game_mode == GameManager.GameMode.CHALLENGE)
	assert(game._progression_round() == reload.start_round)
	assert(game.round_number == reload.target_round - reload.start_round)
	assert(not game.challenge_modifiers.guarantee_playable_hand)
	assert(game.special_rule_manager.disable_rules_on_challenge_first_round)
	assert(game.special_rule_manager.active_rules.is_empty())
	assert(game.bonus_manager.disabled_bonus_ids.has(&"redraw"))
	var deadline := Time.get_ticks_msec() + 5000
	while not game.redraw_button.visible and Time.get_ticks_msec() < deadline:
		await process_frame
	var first_playable_values := game._playable_values()
	assert(not game.hand_manager.current_cards.is_empty())
	for card in game.hand_manager.current_cards:
		assert(not card.is_joker)
		assert(not first_playable_values.has(card.card_value))
	assert(not game._reload_tutorial_hand_pending)
	assert(game.redraw_button.get_parent() == game.redraw_button._tray_parent)
	assert(game.redraw_button.position == Vector2(
		game.hand_tray.size.x - 35.0, 1.0
	))
	assert(game.redraw_button.tooltip_text.is_empty())
	assert(game.redraw_button.highlight_material != null)
	game.redraw_button.mouse_entered.emit()
	assert(game.redraw_button.material == game.redraw_button.highlight_material)
	game.redraw_button.mouse_exited.emit()
	assert(game.redraw_button.material == null)
	game.timer_manager.time_left = 0.4
	game.redraw_button.pressed.emit()
	assert(not game.timer_manager.running)
	assert(is_equal_approx(game.timer_manager.time_left, 2.4))
	deadline = Time.get_ticks_msec() + 3000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)
	assert(game.timer_manager.running)
	assert(game.timer_manager.time_left <= 2.4)
	assert(game.timer_manager.time_left > 2.1)
	var debug_win := InputEventKey.new()
	debug_win.keycode = KEY_E
	debug_win.pressed = true
	var rounds_before_spam := game.round_number
	var lives_lost_before_spam := game.run_lives_lost
	var mistakes_before_spam := game.run_mistake_count
	assert(game._handle_debug_shortcut(debug_win))
	assert(game._handle_debug_shortcut(debug_win))
	assert(game._handle_debug_shortcut(debug_win))
	# A timeout delivered during accelerated debug transitions belongs to the
	# superseded round and must never become delayed damage.
	game._shared_clock_timeout_pending = true
	await game._on_time_expired()
	assert(not game._shared_clock_timeout_pending)
	deadline = Time.get_ticks_msec() + 10000
	while (
		game.round_number > rounds_before_spam - 3
		and Time.get_ticks_msec() < deadline
	):
		await process_frame
	assert(game.round_number == rounds_before_spam - 3)
	assert(game._debug_round_wins_queued == 0)
	assert(game.run_lives_lost == lives_lost_before_spam)
	assert(game.run_mistake_count == mistakes_before_spam)
	assert(not game.overlay.visible)
	game.hand_manager.clear_hand(game.hand_container, true)
	await process_frame
	assert(is_instance_valid(game.redraw_button))
	assert(game.redraw_button.get_parent() == game.redraw_button._tray_parent)
	game.start_game(false, configured, false)
	assert(game.pile_count == 3)
	assert(game.hand_size == 4)
	assert(game.start_value == 7)
	assert(is_equal_approx(game.turn_time, 8.5))
	assert(game.bonus_manager.level(&"redraw") == 2)
	game._achievement_notifications_enabled = false
	await process_frame
	game.queue_free()
	await process_frame
	print("Challenge tests passed.")
	quit()

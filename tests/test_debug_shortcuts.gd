extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_until_unlocked(game)

	assert(game.debug_help.visible)
	assert(game.debug_help.text.contains("DEBUG SHORTCUTS"))
	assert(not game.debug_help.text.contains("[S] NEXT MUSIC SECTION"))
	assert(game.debug_help.mouse_filter == Control.MOUSE_FILTER_PASS)
	game._set_debug_help_expanded(true)
	assert(game.debug_help.text.contains("[S] NEXT MUSIC SECTION"))
	assert(game.debug_help.text.contains("[B] NEXT BACKGROUND"))
	assert(game.debug_help.text.contains("[L] LOSE ONE LIFE"))
	assert(game.debug_help.text.contains("[K] DIE NOW"))
	assert(game.debug_help.text.contains("[U] TOGGLE UNLOCK EVERYTHING"))
	assert(game.debug_help.text.contains("[P] DIFFICULTY PROBABILITIES: OFF"))
	if not DebugSettings.is_unlock_everything_enabled():
		DebugSettings.toggle_unlock_everything()
	game._apply_debug_unlock_everything()
	assert(game.challenge_manager.debug_unlock_all)
	assert(game.max_discovered_tile_value == DifficultySettings.MAX_CARD_VALUE)
	assert(game.max_discovered_pile_count == DifficultySettings.MAX_PILES)
	assert(game.max_discovered_hand_size == DifficultySettings.MAX_HAND_SIZE)
	assert(game.min_discovered_turn_time == DifficultySettings.MIN_TURN_TIME)
	var seed_limits := game._seed_difficulty_limits()
	assert(seed_limits.max_start_value == DifficultySettings.MAX_CARD_VALUE)
	assert(seed_limits.max_pile_count == DifficultySettings.MAX_PILES)
	assert(seed_limits.max_hand_size == DifficultySettings.MAX_HAND_SIZE)
	assert(seed_limits.min_turn_time == DifficultySettings.MIN_TURN_TIME)
	assert(
		game.challenge_manager.completed.size()
		== game.challenge_manager.definitions.size()
	)
	for challenge in game.challenge_manager.definitions:
		assert(game.challenge_manager.is_unlocked(challenge, []))
		assert(game.challenge_manager.completed.has(challenge.id))
	var probability_event := InputEventKey.new()
	probability_event.keycode = KEY_P
	probability_event.pressed = true
	assert(game._handle_debug_shortcut(probability_event))
	assert(game.debug_probability_panel.visible)
	assert(game.debug_probability_panel.text.contains("NO CHANGE"))
	assert(game.debug_probability_panel.text.contains("EXTRA STAT"))
	assert(game.debug_help.text.contains("[P] DIFFICULTY PROBABILITIES: ON"))
	var section_event := InputEventKey.new()
	section_event.keycode = KEY_S
	section_event.pressed = true
	var initial_section := game.music_manager.current_section
	assert(game._handle_debug_shortcut(section_event))
	assert(game.music_manager.current_section in [initial_section, initial_section + 1])
	assert(
		game.music_manager.section_change_requested
		or game.music_manager.current_section == initial_section + 1
	)
	var background_event := InputEventKey.new()
	background_event.keycode = KEY_B
	background_event.pressed = true
	assert(game._handle_debug_shortcut(background_event))
	assert(game.background_manager.last_background_id != &"")

	var initial_god_mode := DebugSettings.is_god_mode_enabled()
	var god_event := InputEventKey.new()
	god_event.keycode = KEY_G
	god_event.pressed = true
	assert(game._handle_debug_shortcut(god_event))
	assert(DebugSettings.is_god_mode_enabled() != initial_god_mode)
	assert(game.debug_help.text.contains("GOD MODE: ON"))

	var reset_event := InputEventKey.new()
	reset_event.keycode = KEY_R
	reset_event.pressed = true
	assert(game._handle_debug_shortcut(reset_event))
	await _wait_until_unlocked(game)
	assert(game.round_number == DifficultySettings.TOTAL_ROUNDS)
	# Restart remains available while a round transition owns the gameplay lock,
	# and its iris is shown immediately over that transition.
	game.input_locked = true
	assert(game._handle_debug_shortcut(reset_event))
	await process_frame
	assert(game.replay_transition_mask.visible)
	await _wait_until_unlocked(game)
	game.pile_count = DifficultySettings.START_PILES + 1
	game.splash.visible = true
	assert(not game._handle_debug_shortcut(reset_event))
	assert(game.pile_count == DifficultySettings.START_PILES + 1)
	assert(not game._handle_debug_shortcut(god_event))
	assert(DebugSettings.is_god_mode_enabled() != initial_god_mode)
	assert(not game._handle_debug_shortcut(probability_event))
	assert(game.debug_probability_panel.visible)

	game.best_rounds_left = 12
	game.best_score_time_ms = 1234
	game.unlocked_checkpoints.assign([1, 2])
	game.checkpoint_snapshots = {1: {"start_round": 10}}
	game.discovered_bonuses.assign([&"wild_card"])
	game.achievement_manager.unlocked.assign([&"max_piles"])
	game.challenge_manager.completed.assign([&"reload_required"])
	game.challenge_manager.highscores[&"reload_required"] = 12
	game.challenge_manager.endless_highscores[&"reload_required"] = 21
	game.challenge_manager.best_times_ms[&"reload_required"] = 1234
	var high_score_event := InputEventKey.new()
	high_score_event.keycode = KEY_H
	high_score_event.pressed = true
	assert(game._handle_debug_shortcut(high_score_event))
	assert(game.best_rounds_left == -1)
	assert(game.best_score_time_ms == -1)
	assert(game.unlocked_checkpoints.is_empty())
	assert(game.checkpoint_snapshots.is_empty())
	assert(game.discovered_bonuses.is_empty())
	assert(game.achievement_manager.unlocked.is_empty())
	assert(not game.challenge_manager.debug_unlock_all)
	assert(game.challenge_manager.completed.is_empty())
	assert(game.challenge_manager.highscores.is_empty())
	assert(game.challenge_manager.endless_highscores.is_empty())
	assert(game.challenge_manager.best_times_ms.is_empty())
	assert(game.splash_high_score.text.contains("--"))

	print("Debug shortcut integration test passed.")
	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while (
		(game.input_locked or game._screen_transition_active)
		and Time.get_ticks_msec() < deadline
	):
		await process_frame
	assert(not game.input_locked)
	assert(not game._screen_transition_active)

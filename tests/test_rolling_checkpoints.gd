extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(40.0).timeout.connect(func() -> void: quit(1))
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.unlocked_checkpoints.clear()
	game.checkpoint_snapshots.clear()
	game._checkpoint_candidates.clear()
	game.newly_unlocked_checkpoints.clear()
	game.checkpoint_flawless_rounds = 0
	game.checkpoint_segment_damage_count = 0
	game.game_mode = GameManager.GameMode.STANDARD
	var saved_milestones: Dictionary = {}
	# Losing a life in rounds 1 and 6 prevents both fixed sections from qualifying.
	# Only the sliding window 7..11 may catch up milestones 5 and 10.
	for completed_round in range(1, 12):
		game.round_number = DifficultySettings.TOTAL_ROUNDS - completed_round + 1
		game.pile_count = 1 + int(completed_round / 5)
		game.hand_size = 2
		game.start_value = 5
		game.turn_time = 4.0
		game._capture_checkpoint_candidate()
		if completed_round in [5, 10]:
			var checkpoint_id := int(completed_round / 5)
			saved_milestones[checkpoint_id] = game._checkpoint_candidates[checkpoint_id].duplicate(true)
		game.checkpoint_segment_damage_count = 1 if completed_round in [1, 6] else 0
		var unlocked := game._unlock_completed_checkpoint(completed_round)
		assert(unlocked == (completed_round == 11))
		if completed_round < 11:
			assert(game.unlocked_checkpoints.is_empty())
	assert(game.unlocked_checkpoints == [1, 2])
	assert(game.newly_unlocked_checkpoints == [1, 2])
	assert(game.checkpoint_snapshots[1] == saved_milestones[1])
	assert(game.checkpoint_snapshots[2] == saved_milestones[2])
	var config := SaveConfig.load_current()
	assert(config.get_value("checkpoints", "unlocked") == [1, 2])
	game._load_checkpoint_progress(config)
	assert(game.unlocked_checkpoints == [1, 2])
	assert(game.checkpoint_snapshots[1] == saved_milestones[1])

	# Challenges must never unlock global checkpoints, even with a clean window.
	game.game_mode = GameManager.GameMode.CHALLENGE
	game.checkpoint_flawless_rounds = 5
	assert(not game._unlock_completed_checkpoint(30))
	assert(game.unlocked_checkpoints == [1, 2])
	game.game_mode = GameManager.GameMode.ENDLESS
	game._checkpoint_candidates[3] = game.CheckpointProgressStoreScript.create_fallback_snapshot(game, 3).to_dictionary()
	assert(game._unlock_completed_checkpoint(15))
	assert(game.unlocked_checkpoints == [1, 2, 3])

	# Starting and replaying a checkpoint clears the previous clean window.
	game._debug_action_in_progress = true
	assert(game.start_from_checkpoint(2, {}, true))
	assert(game.checkpoint_flawless_rounds == 0)
	assert(game._checkpoint_candidates.is_empty())
	await _wait_until_unlocked(game)
	game.special_rule_manager.forced_rule_ids.assign([&"roman_holiday"])
	game.bonus_manager.grant_starting_bonuses({&"safety_net": 1})
	game.bonus_manager.begin_round()
	for bonus in BonusRegistry.create_all():
		game.bonus_manager.disabled_bonus_ids.append(bonus.id)
	game.checkpoint_flawless_rounds = 4
	var previous_lives := game.mistakes_left
	await game._handle_mistake()
	assert(game.mistakes_left == previous_lives)
	assert(game.checkpoint_flawless_rounds == 4, "Absorbed mistakes must preserve the window")
	await game._handle_mistake()
	assert(game.mistakes_left == previous_lives - 1)
	assert(game.checkpoint_flawless_rounds == 0, "Actual life loss must reset the window")
	game.timer_manager.stop_countdown()
	game.unlocked_checkpoints.erase(3)
	game.checkpoint_snapshots.erase(3)
	var emitted: Array[int] = []
	game.achievement_manager.checkpoint_unlocked.connect(
		func(checkpoint_id: int, _ids: Array[int]) -> void: emitted.append(checkpoint_id)
	)
	for completed_round in range(10, 16):
		assert(game.round_number == completed_round)
		game._debug_round_wins_queued = 1
		await game._finish_round()
		game._debug_round_wins_queued = 0
		if completed_round < 15:
			assert(not game.unlocked_checkpoints.has(3))
			game.special_rule_manager.suppress_next_announcement = true
			game.start_round()
			await _wait_until_unlocked(game)
	assert(game.unlocked_checkpoints.has(3), "Checkpoint runs must unlock later milestones")
	assert(game.newly_unlocked_checkpoints == [3])
	assert(emitted.has(3), "The actual newly unlocked checkpoint must reach achievements")
	assert(game.checkpoint_snapshots[1] == saved_milestones[1])
	assert(game.checkpoint_snapshots[2] == saved_milestones[2])
	game.start_from_checkpoint(2, {}, true)
	assert(game.checkpoint_flawless_rounds == 0)
	await _wait_until_unlocked(game)
	game.game_mode = GameManager.GameMode.STANDARD
	game.splash.visible = false
	game.start_game()
	assert(game.checkpoint_flawless_rounds == 0)
	assert(game._checkpoint_candidates.is_empty())
	await _wait_until_unlocked(game)
	game.queue_free()
	await process_frame
	print("Rolling checkpoint tests passed.")
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

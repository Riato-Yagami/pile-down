extends SceneTree

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := AchievementManager.new()
	root.add_child(manager)
	# New profiles must persist an empty qualified baseline before discoveries.
	manager.load_progress()
	for mode in [RunSummary.Mode.CHALLENGE, RunSummary.Mode.CHECKPOINT]:
		manager.configure_run(mode)
		assert(not manager.unlock(&"max_hand"))
		assert(manager.can_unlock(&"double_down_deja_vu_combo"))
		manager.configure_run(mode, true)
		assert(not manager.can_unlock(&"double_down_deja_vu_combo"))
	manager.configure_run(RunSummary.Mode.CHALLENGE, false, false)
	assert(not manager.can_unlock(&"complete_boss_rush"))
	manager.configure_run(RunSummary.Mode.CHALLENGE)
	assert(manager.can_unlock(&"complete_boss_rush"))
	manager.configure_run(RunSummary.Mode.NORMAL, true)
	var all_bonuses: Array[StringName] = Difficulty.ENABLED_BONUSES.duplicate()
	for bonus_id in all_bonuses:
		var bonus := BonusRegistry.get_bonus(bonus_id)
		manager.bonus_acquired.emit(bonus_id, bonus.max_level, {bonus_id: bonus.max_level}, all_bonuses)
	var all_rules: Array[StringName] = Difficulty.ENABLED_SPECIAL_RULES.duplicate()
	manager.special_rule_round_completed.emit(all_rules, all_rules)
	var checkpoints := AchievementManager.normal_checkpoint_ids()
	for checkpoint_id in checkpoints:
		manager.checkpoint_unlocked.emit(checkpoint_id, checkpoints)
	assert(manager.unlocked.is_empty())
	assert(manager.qualified_bonus_ids.is_empty())
	assert(manager.qualified_rule_ids.is_empty())
	assert(manager.qualified_checkpoint_ids.is_empty())
	assert(manager.bonuses_maxed_once.is_empty())
	assert(manager.qualified_protection_levels.is_empty())
	assert(not manager.bonus_highest_levels.is_empty())
	# General discoveries from excluded runs must not be migrated on reload.
	var config := SaveConfig.load_current()
	config.set_value("progression", "discovered_bonuses", all_bonuses)
	config.set_value("progression", "beaten_special_rules", all_rules)
	config.set_value("checkpoints", "unlocked", checkpoints)
	assert(config.save(SaveConfig.PATH) == OK)
	var restored := AchievementManager.new()
	root.add_child(restored)
	restored.load_progress()
	assert(restored.qualified_bonus_ids.is_empty())
	assert(restored.qualified_rule_ids.is_empty())
	assert(restored.qualified_checkpoint_ids.is_empty())
	restored.configure_run(RunSummary.Mode.NORMAL)
	restored.bonus_acquired.emit(&"open_book", 1, {&"open_book": 1}, all_bonuses)
	var no_rules: Array[StringName] = []
	restored.special_rule_round_completed.emit(no_rules, all_rules)
	restored.checkpoint_unlocked.emit(checkpoints[0], checkpoints)
	assert(not restored.unlocked.has(&"all_bonuses_discovered"))
	assert(not restored.unlocked.has(&"beat_all_special_rules"))
	assert(not restored.unlocked.has(&"all_checkpoints"))
	# Permissions can be changed independently in data, including seeded modes.
	var custom := restored.find(&"max_hand").duplicate() as AchievementData
	custom.allow_normal = false
	custom.allow_checkpoints = true
	custom.allow_seeded = true
	assert(not custom.allows_run(RunSummary.Mode.NORMAL, false))
	assert(custom.allows_run(RunSummary.Mode.CHECKPOINT, true))
	assert(not custom.allows_run(RunSummary.Mode.CHALLENGE, true))
	# Seeded challenge completion cannot prefill the all-challenges achievement.
	var challenges := ChallengeRegistry.create_all()
	var completed: Array[StringName] = []
	for challenge in challenges:
		completed.append(challenge.id)
	manager.configure_run(RunSummary.Mode.CHALLENGE, true)
	for challenge in challenges:
		manager.record_challenge_completion(challenge.id, completed, challenges)
	assert(manager.unlocked.is_empty())
	manager.configure_run(RunSummary.Mode.CHALLENGE)
	manager.record_challenge_completion(challenges[0].id, completed, challenges)
	assert(not manager.unlocked.has(&"challenge_accepted"))
	for challenge in challenges:
		manager.record_challenge_completion(challenge.id, completed, challenges)
	assert(manager.unlocked.has(&"challenge_accepted"))
	manager.queue_free()
	restored.queue_free()
	await process_frame
	await _test_game_context()
	print("Achievement mode tests passed.")
	quit()


func _test_game_context() -> void:
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	var challenge := game.challenge_manager.find(&"boss_rush").duplicate() as ChallengeData
	challenge.allow_achievement_unlocks = false
	game.start_game(false, challenge)
	await _wait_for_hand(game)
	assert(not game.achievement_manager.can_unlock(&"complete_boss_rush"))
	assert(not game._build_run_summary(false).allow_achievement_unlocks)
	game.start_game(false, null, false, "ACHIEVEMENT-TEST")
	await _wait_for_hand(game)
	assert(game._build_run_summary(false).is_seeded)
	assert(not game.achievement_manager.can_unlock(&"max_hand"))
	var snapshot := CheckpointSnapshot.new()
	snapshot.checkpoint_id = 1
	snapshot.start_round = Difficulty.CHECKPOINT_INTERVAL
	snapshot.pile_count = Difficulty.START_PILES
	snapshot.hand_size = Difficulty.START_HAND_SIZE
	snapshot.start_value = Difficulty.START_CARD_VALUE
	snapshot.turn_time = Difficulty.START_TURN_TIME
	game.checkpoint_snapshots[1] = snapshot.to_dictionary()
	assert(game.start_from_checkpoint(1, {}, true))
	await _wait_for_hand(game)
	assert(not game.achievement_manager.can_unlock(&"max_hand"))
	assert(game.achievement_manager.can_unlock(&"double_down_deja_vu_combo"))
	assert(game._build_run_summary(false).mode == RunSummary.Mode.CHECKPOINT)
	assert(game.start_from_checkpoint(1, {}, true, "CHECKPOINT-SEED"))
	await _wait_for_hand(game)
	assert(not game.achievement_manager.can_unlock(&"double_down_deja_vu_combo"))
	game.queue_free()
	await process_frame


func _wait_for_hand(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while (game.splash.visible or game.input_locked or game.hand_manager.current_cards.is_empty()) and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.splash.visible and not game.input_locked)
	assert(not game.hand_manager.current_cards.is_empty())

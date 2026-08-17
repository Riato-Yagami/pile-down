extends SceneTree

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_registry_and_feasibility()
	await _test_stat_limits()
	await _test_rounds_lives_checkpoints_and_speedruns()
	await _test_cumulative_progression()
	await _test_combos()
	await _test_save_reload_and_migration()
	print("Achievement tests passed.")
	quit()


func _new_manager() -> AchievementManager:
	var manager := AchievementManager.new()
	root.add_child(manager)
	return manager


func _test_registry_and_feasibility() -> void:
	var declared := AchievementRegistry.create_declared()
	assert(declared.size() >= 41)
	var ids: Array[StringName] = []
	for data in declared:
		assert(not ids.has(data.id))
		assert(not data.category.is_empty())
		ids.append(data.id)
	assert(AchievementRegistry.create_all().size() == declared.size())
	assert(AchievementRegistry.create_all().any(
		func(data: AchievementData) -> bool:
			return data.id == &"all_bonuses_maxed_once"
	))
	assert(Difficulty.MAX_ROUNDS == Difficulty.TOTAL_ROUNDS)
	assert(AchievementManager.half_round_target(50) == 25)
	assert(AchievementManager.half_round_target(51) == 26)
	var enabled_subset: Array[StringName] = [&"enabled_a", &"enabled_b"]
	var discovered_subset: Array[StringName] = [&"enabled_a", &"enabled_b"]
	assert(AchievementManager._contains_all_enabled(
		discovered_subset, enabled_subset
	))


func _test_stat_limits() -> void:
	var manager := _new_manager()
	manager.difficulty_stat_changed.emit(&"pile_count", Difficulty.MAX_PILES - 1)
	assert(not manager.unlocked.has(&"max_piles"))
	manager.difficulty_stat_changed.emit(&"pile_count", Difficulty.MAX_PILES)
	manager.difficulty_stat_changed.emit(&"hand_size", Difficulty.MAX_HAND_SIZE)
	manager.difficulty_stat_changed.emit(&"turn_time", Difficulty.MIN_TURN_TIME + 0.01)
	assert(not manager.unlocked.has(&"minimum_timer"))
	manager.difficulty_stat_changed.emit(&"turn_time", Difficulty.MIN_TURN_TIME)
	manager.difficulty_stat_changed.emit(&"start_value", 9)
	assert(manager.unlocked.has(&"max_piles"))
	assert(manager.unlocked.has(&"max_hand"))
	assert(manager.unlocked.has(&"minimum_timer"))
	assert(manager.unlocked.has(&"start_value_nine"))
	manager.queue_free()


func _test_rounds_lives_checkpoints_and_speedruns() -> void:
	var half := AchievementManager.half_round_target(Difficulty.MAX_ROUNDS)
	var manager := _new_manager()
	var no_rules: Array[StringName] = []
	var summary := RunSummary.new()
	summary.mode = RunSummary.Mode.NORMAL
	summary.completed_rounds = 1
	manager.round_completed.emit(summary, 1, no_rules)
	assert(manager.unlocked.has(&"first_round"))
	manager.unlocked.clear()
	summary.completed_rounds = half - 1
	summary.run_time_seconds = 10.0
	manager.round_completed.emit(summary, half - 1, no_rules)
	assert(not manager.unlocked.has(&"complete_half_game"))
	summary.completed_rounds = half
	summary.mistakes_made = 2
	summary.lives_lost = 0
	manager.round_completed.emit(summary, half, no_rules)
	assert(manager.unlocked.has(&"complete_half_game"))
	assert(manager.unlocked.has(&"half_no_life_lost"))

	manager.unlocked.clear()
	summary.lives_lost = 1
	manager.round_completed.emit(summary, half, no_rules)
	assert(not manager.unlocked.has(&"half_no_life_lost"))
	manager.unlocked.clear()
	summary.started_from_checkpoint = true
	summary.mode = RunSummary.Mode.CHECKPOINT
	summary.lives_lost = 0
	manager.round_completed.emit(summary, half, no_rules)
	assert(manager.unlocked.has(&"complete_half_game"))
	assert(not manager.unlocked.has(&"half_without_checkpoint"))
	assert(not manager.unlocked.has(&"speedrun_10_rounds"))

	manager.unlocked.clear()
	summary.started_from_checkpoint = false
	summary.mode = RunSummary.Mode.NORMAL
	summary.completed_rounds = 10
	summary.run_time_seconds = 300.0
	manager.round_completed.emit(summary, 10, no_rules)
	assert(not manager.unlocked.has(&"speedrun_10_rounds"))
	summary.run_time_seconds = 299.999
	manager.round_completed.emit(summary, 10, no_rules)
	assert(manager.unlocked.has(&"speedrun_10_rounds"))
	var speedrun_data := manager.find(&"speedrun_10_rounds")
	speedrun_data.time_limit_seconds = 250.0
	manager.unlocked.clear()
	summary.run_time_seconds = 275.0
	manager.round_completed.emit(summary, 10, no_rules)
	assert(not manager.unlocked.has(&"speedrun_10_rounds"))
	speedrun_data.time_limit_seconds = 300.0
	manager.unlocked.clear()
	summary.completed_rounds = 20
	summary.run_time_seconds = 600.0
	manager.round_completed.emit(summary, 20, no_rules)
	assert(not manager.unlocked.has(&"speedrun_20_rounds"))
	summary.run_time_seconds = 599.999
	manager.round_completed.emit(summary, 20, no_rules)
	assert(manager.unlocked.has(&"speedrun_20_rounds"))
	assert(manager.unlocked.has(&"round_20_without_bonuses"))
	manager.unlocked.clear()
	summary.active_bonus_levels = {&"open_book": 1}
	manager.round_completed.emit(summary, 20, no_rules)
	assert(not manager.unlocked.has(&"round_20_without_bonuses"))
	summary.active_bonus_levels.clear()

	manager.unlocked.clear()
	summary.completed_rounds = Difficulty.MAX_ROUNDS
	summary.normal_game_completed = true
	summary.run_time_seconds = 1800.0
	manager.run_completed.emit(summary)
	assert(not manager.unlocked.has(&"speedrun_full_game"))
	assert(manager.unlocked.has(&"game_without_bonuses"))
	manager.unlocked.clear()
	summary.active_bonus_levels = {&"open_book": 1}
	manager.run_completed.emit(summary)
	assert(not manager.unlocked.has(&"game_without_bonuses"))
	summary.active_bonus_levels.clear()
	summary.run_time_seconds = 1799.999
	manager.run_completed.emit(summary)
	assert(manager.unlocked.has(&"speedrun_full_game"))

	var checkpoint_ids := AchievementManager.normal_checkpoint_ids()
	assert(checkpoint_ids.size() == int(
		Difficulty.MAX_ROUNDS / Difficulty.CHECKPOINT_INTERVAL
	))
	manager.unlocked.clear()
	var first_checkpoint_ids: Array[int] = [checkpoint_ids[0]]
	manager.checkpoint_unlocked.emit(checkpoint_ids[0], first_checkpoint_ids)
	assert(manager.unlocked.has(&"first_checkpoint"))
	assert(not manager.unlocked.has(&"all_checkpoints"))
	manager.checkpoint_unlocked.emit(checkpoint_ids.back(), checkpoint_ids)
	assert(manager.unlocked.has(&"all_checkpoints"))
	manager.queue_free()


func _test_cumulative_progression() -> void:
	var manager := _new_manager()
	var no_rules: Array[StringName] = []
	var no_ids: Array[StringName] = []
	var discovered: Array[StringName] = Difficulty.ENABLED_BONUSES.duplicate()
	manager.bonus_acquired.emit(&"open_book", 1, {&"open_book": 1}, discovered)
	assert(manager.unlocked.has(&"all_bonuses_discovered"))
	var beaten: Array[StringName] = Difficulty.ENABLED_SPECIAL_RULES.duplicate()
	manager.special_rule_round_completed.emit(no_rules, beaten)
	assert(manager.unlocked.has(&"beat_all_special_rules"))
	manager.unlocked.clear()
	manager.bonus_acquired.emit(&"pile_mover", 1, {&"pile_mover": 1}, no_ids)
	assert(not manager.unlocked.has(&"one_bonus_max_level"))
	assert(bool(manager.bonuses_maxed_once.get(&"pile_mover", false)))
	manager.bonus_acquired.emit(&"double_down", 3, {&"double_down": 3}, no_ids)
	assert(manager.unlocked.has(&"one_bonus_max_level"))
	for bonus_id in Difficulty.ENABLED_BONUSES:
		if bonus_id != &"double_down":
			manager.bonuses_maxed_once[bonus_id] = true
	manager.check_maximum_build_achievement()
	assert(manager.unlocked.has(&"all_bonuses_maxed_once"))
	manager.queue_free()


func _test_combos() -> void:
	var manager := _new_manager()
	var first := HandComboSummary.new()
	first.root_action_id = 10
	first.double_down_count = 1
	manager.hand_combo_resolved.emit(first)
	var second := HandComboSummary.new()
	second.root_action_id = 11
	second.deja_vu_count = 1
	manager.hand_combo_resolved.emit(second)
	assert(not manager.unlocked.has(&"double_down_deja_vu_combo"))
	var combined := HandComboSummary.new()
	combined.root_action_id = 12
	combined.double_down_count = 1
	combined.deja_vu_count = 1
	manager.hand_combo_resolved.emit(combined)
	assert(manager.unlocked.has(&"double_down_deja_vu_combo"))

	manager.unlocked.clear()
	combined.bonus_levels = {
		&"double_down": 2, &"deja_vu": 2, &"bring_a_friend": 2,
	}
	combined.double_down_count = 3
	combined.deja_vu_count = 3
	combined.bring_a_friend_count = 3
	combined.bring_a_friend_total_companions = 3
	combined.bring_a_friend_all_succeeded = true
	manager.hand_combo_resolved.emit(combined)
	assert(not manager.unlocked.has(&"double_down_full_activation"))
	assert(not manager.unlocked.has(&"deja_vu_full_activation"))
	assert(not manager.unlocked.has(&"bring_a_friend_full_activation"))
	combined.bonus_levels = {
		&"double_down": 3, &"deja_vu": 3, &"bring_a_friend": 3,
	}
	manager.hand_combo_resolved.emit(combined)
	assert(manager.unlocked.has(&"double_down_full_activation"))
	assert(manager.unlocked.has(&"deja_vu_full_activation"))
	assert(manager.unlocked.has(&"bring_a_friend_full_activation"))
	manager.queue_free()


func _test_save_reload_and_migration() -> void:
	var config := ConfigFile.new()
	config.set_value("progression", "unlocked_achievements", [&"max_piles"])
	assert(config.save(AchievementManager.SAVE_PATH) == OK)
	var manager := _new_manager()
	manager.load_progress()
	var popup_count := 0
	manager.achievement_unlocked.connect(
		func(_data: AchievementData) -> void: popup_count += 1
	)
	manager.difficulty_stat_changed.emit(&"pile_count", Difficulty.MAX_PILES)
	assert(popup_count == 0)
	manager.queue_free()

	var legacy := ConfigFile.new()
	legacy.set_value("progression", "discovered_bonuses", [])
	assert(legacy.save(AchievementManager.SAVE_PATH) == OK)
	var migrated := _new_manager()
	migrated.load_progress()
	assert(migrated.unlocked.is_empty())
	migrated.queue_free()

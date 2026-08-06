class_name AchievementManager
extends Node

signal achievement_unlocked(data: AchievementData)
signal difficulty_stat_changed(stat_id: StringName, new_value: Variant)
signal round_completed(summary: RunSummary, completed_round: int, rule_ids: Array[StringName])
signal checkpoint_unlocked(checkpoint_id: int, unlocked_ids: Array[int])
signal bonus_acquired(
	bonus_id: StringName,
	level: int,
	active_levels: Dictionary,
	discovered_ids: Array[StringName]
)
signal special_rule_round_completed(
	rule_ids: Array[StringName], beaten_ids: Array[StringName]
)
signal hand_combo_resolved(summary: HandComboSummary)
signal life_lost()
signal run_completed(summary: RunSummary)

const SAVE_PATH := "user://pile_down.cfg"
const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")

var definitions: Array[AchievementData] = AchievementRegistry.create_all()
var unlocked: Array[StringName] = []
var unlock_dates: Dictionary = {}
var bonuses_maxed_once: Dictionary = {}
var bonus_highest_levels: Dictionary = {}


func _ready() -> void:
	difficulty_stat_changed.connect(_on_difficulty_stat_changed)
	round_completed.connect(_on_round_completed)
	checkpoint_unlocked.connect(_on_checkpoint_unlocked)
	bonus_acquired.connect(_on_bonus_acquired)
	special_rule_round_completed.connect(_on_special_rule_round_completed)
	hand_combo_resolved.connect(_on_hand_combo_resolved)
	run_completed.connect(_on_run_completed)


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Array = config.get_value(
		"progression", "unlocked_achievements", []
	)
	for value in saved:
		var id := StringName(value)
		if id == &"all_bonuses_max_level":
			id = &"all_bonuses_maxed_once"
		if not unlocked.has(id):
			unlocked.append(id)
	unlock_dates = config.get_value(
		"progression", "achievement_unlock_dates", {}
	)
	bonuses_maxed_once = config.get_value(
		"progression", "bonuses_maxed_once", {}
	)
	bonus_highest_levels = config.get_value(
		"progression", "bonus_highest_levels", {}
	)


func unlock(id: StringName, persist := true) -> bool:
	if unlocked.has(id):
		return false
	var data := find(id)
	if data == null:
		return false
	unlocked.append(id)
	unlock_dates[id] = Time.get_datetime_string_from_system(false, true)
	if persist:
		_save()
	achievement_unlocked.emit(data)
	return true


func find(id: StringName) -> AchievementData:
	for data in definitions:
		if data.id == id:
			return data
	return null


func _on_difficulty_stat_changed(stat_id: StringName, new_value: Variant) -> void:
	match stat_id:
		&"pile_count":
			if int(new_value) >= Difficulty.MAX_PILES:
				unlock(&"max_piles")
		&"hand_size":
			if int(new_value) >= Difficulty.MAX_HAND_SIZE:
				unlock(&"max_hand")
		&"turn_time":
			if float(new_value) < Difficulty.MIN_TURN_TIME or is_equal_approx(
				float(new_value), Difficulty.MIN_TURN_TIME
			):
				unlock(&"minimum_timer")
		&"start_value":
			if int(new_value) >= 9:
				unlock(&"start_value_nine")


func _on_round_completed(
	summary: RunSummary,
	completed_round: int,
	rule_ids: Array[StringName]
) -> void:
	var half_rounds := half_round_target(Difficulty.MAX_ROUNDS)
	var normal_progression := (
		summary.mode == RunSummary.Mode.NORMAL
		or (
			summary.mode == RunSummary.Mode.CHECKPOINT
			and not summary.uses_endless_progression
		)
	)
	if summary.completed_rounds >= 10:
		unlock(&"complete_10_rounds")
	if normal_progression and summary.completed_rounds >= half_rounds:
		unlock(&"complete_half_game")
		if (
			summary.mode == RunSummary.Mode.NORMAL
			and not summary.started_from_checkpoint
		):
			unlock(&"half_without_checkpoint")
			if summary.lives_lost == 0:
				unlock(&"half_no_life_lost")
	if summary.mode == RunSummary.Mode.ENDLESS:
		if completed_round >= Difficulty.MAX_ROUNDS + 1:
			unlock(&"endless_max_plus_one")
		if completed_round >= Difficulty.MAX_ROUNDS * 2:
			unlock(&"endless_double_max")
	if rule_ids.size() >= 2:
		unlock(&"beat_two_special_rules")
	if rule_ids.size() >= Difficulty.MAX_COMBINED_RULES:
		unlock(&"beat_max_special_rules")
	_evaluate_speedrun_milestones(summary)


func _on_checkpoint_unlocked(_checkpoint_id: int, unlocked_ids: Array[int]) -> void:
	if not unlocked_ids.is_empty():
		unlock(&"first_checkpoint")
	var expected := normal_checkpoint_ids()
	if not expected.is_empty() and expected.all(
		func(id: int) -> bool: return unlocked_ids.has(id)
	):
		unlock(&"all_checkpoints")


func _on_bonus_acquired(
	bonus_id: StringName,
	level: int,
	active_levels: Dictionary,
	discovered_ids: Array[StringName]
) -> void:
	register_bonus_level(bonus_id, level)
	var data := _find_bonus(bonus_id)
	if data != null and data.max_level > 1 and level >= data.max_level:
		unlock(&"one_bonus_max_level")
	if active_levels.size() >= 5:
		unlock(&"five_different_bonuses")
	if _contains_all_enabled(discovered_ids, Difficulty.ENABLED_BONUSES):
		unlock(&"all_bonuses_discovered")


func register_bonus_level(bonus_id: StringName, current_level: int) -> void:
	var bonus_data := BonusRegistry.get_bonus(bonus_id)
	if bonus_data == null:
		return
	var previous_best := int(bonus_highest_levels.get(bonus_id, 0))
	if current_level > previous_best:
		bonus_highest_levels[bonus_id] = current_level
	if current_level < bonus_data.max_level:
		if current_level > previous_best:
			_save()
		return
	if not bool(bonuses_maxed_once.get(bonus_id, false)):
		bonuses_maxed_once[bonus_id] = true
		_save()
	check_maximum_build_achievement()


func check_maximum_build_achievement() -> void:
	for bonus_id in Difficulty.ENABLED_BONUSES:
		if not bool(bonuses_maxed_once.get(bonus_id, false)):
			return
	unlock(&"all_bonuses_maxed_once")


func _on_special_rule_round_completed(
	_rule_ids: Array[StringName], beaten_ids: Array[StringName]
) -> void:
	if _contains_all_enabled(beaten_ids, Difficulty.ENABLED_SPECIAL_RULES):
		unlock(&"beat_all_special_rules")


func _on_hand_combo_resolved(summary: HandComboSummary) -> void:
	if summary.double_down_count > 0 and summary.deja_vu_count > 0:
		unlock(&"double_down_deja_vu_combo")
	if (
		summary.bring_a_friend_count > 0
		and summary.double_down_count > 0
		and summary.deja_vu_count > 0
	):
		unlock(&"three_bonus_combo")
	if (
		int(summary.bonus_levels.get(&"double_down", 0)) >= 3
		and summary.double_down_count == 3
	):
		unlock(&"double_down_full_activation")
	if (
		int(summary.bonus_levels.get(&"deja_vu", 0)) >= 3
		and summary.deja_vu_count == 3
	):
		unlock(&"deja_vu_full_activation")
	if (
		int(summary.bonus_levels.get(&"bring_a_friend", 0)) >= 3
		and summary.bring_a_friend_total_companions > 0
		and summary.bring_a_friend_count
		== summary.bring_a_friend_total_companions
		and summary.bring_a_friend_all_succeeded
	):
		unlock(&"bring_a_friend_full_activation")


func _on_run_completed(summary: RunSummary) -> void:
	if not summary.normal_game_completed:
		return
	unlock(&"complete_normal_game")
	if not summary.started_from_checkpoint:
		unlock(&"complete_without_checkpoint")
		if summary.lives_lost == 0:
			unlock(&"complete_no_life_lost")
	_evaluate_speedrun_milestones(summary)


func _evaluate_speedrun_milestones(summary: RunSummary) -> void:
	if summary.mode != RunSummary.Mode.NORMAL or summary.started_from_checkpoint:
		return
	if summary.completed_rounds >= 10 and summary.run_time_seconds < 300.0:
		unlock(&"speedrun_10_rounds")
	if summary.completed_rounds >= 20 and summary.run_time_seconds < 600.0:
		unlock(&"speedrun_20_rounds")
	if summary.normal_game_completed and summary.run_time_seconds < 1800.0:
		unlock(&"speedrun_full_game")


static func normal_checkpoint_ids() -> Array[int]:
	var ids: Array[int] = []
	if not Difficulty.ENABLE_CHECKPOINTS or Difficulty.CHECKPOINT_INTERVAL <= 0:
		return ids
	for round_value in range(
		Difficulty.CHECKPOINT_INTERVAL,
		Difficulty.MAX_ROUNDS + 1,
		Difficulty.CHECKPOINT_INTERVAL
	):
		ids.append(int(round_value / Difficulty.CHECKPOINT_INTERVAL))
	return ids


static func half_round_target(max_rounds: int) -> int:
	return ceili(max_rounds / 2.0)


func _find_bonus(id: StringName) -> BonusData:
	return BonusRegistry.get_bonus(id)


static func _contains_all_enabled(
	values: Array[StringName], enabled: Array[StringName]
) -> bool:
	for id in enabled:
		if not values.has(id):
			return false
	return true


func _save() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("progression", "unlocked_achievements", unlocked)
	config.set_value("progression", "achievement_unlock_dates", unlock_dates)
	config.set_value("progression", "bonuses_maxed_once", bonuses_maxed_once)
	config.set_value("progression", "bonus_highest_levels", bonus_highest_levels)
	config.save(SAVE_PATH)

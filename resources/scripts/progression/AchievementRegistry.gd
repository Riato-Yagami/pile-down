class_name AchievementRegistry
extends RefCounted

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")

const STATS := &"STATS"
const ROUNDS := &"ROUNDS"
const CHECKPOINTS := &"CHECKPOINTS"
const ENDLESS := &"ENDLESS"
const BONUSES_RULES := &"BONUSES & RULES"
const COMBOS := &"COMBOS"
const SPEEDRUN := &"SPEEDRUN"


static func create_all() -> Array[AchievementData]:
	return create_declared()


static func create_declared() -> Array[AchievementData]:
	return [
		_data(&"max_piles", "STACK OVERFLOW", "Reach the maximum number of stacks.", STATS),
		_data(&"max_hand", "FULL HAND", "Reach the maximum hand size.", STATS),
		_data(&"minimum_timer", "FINAL SECONDS", "Reach the shortest possible timer.", STATS),
		_data(&"start_value_nine", "CLOUD NINE", "Reach a starting tile value of 9.", STATS),
		_data(&"complete_10_rounds", "GETTING STARTED", "Complete 10 rounds.", ROUNDS, false, &"tiny5"),
		_data(&"complete_half_game", "HALFWAY DOWN", "Complete half of the normal game.", ROUNDS),
		_data(&"complete_normal_game", "COUNTED DOWN", "Complete every round.", ROUNDS),
		_data(&"half_without_checkpoint", "NO SHORTCUTS", "Complete half the game from the beginning.", ROUNDS),
		_data(&"complete_without_checkpoint", "THE LONG WAY DOWN", "Complete the game from the beginning.", ROUNDS),
		_data(&"half_no_life_lost", "FLAWLESS HALF", "Complete half the game without losing a life.", ROUNDS),
		_data(&"complete_no_life_lost", "PERFECT COUNTDOWN", "Complete the entire game without losing a life.", ROUNDS, true, &"vcr"),
		_data(&"first_checkpoint", "CHECKED IN", "Unlock your first checkpoint.", CHECKPOINTS),
		_data(&"all_checkpoints", "ALL STOPS", "Unlock every checkpoint in Normal Mode.", CHECKPOINTS),
		_data(&"endless_max_plus_one", "ONE MORE ROUND", "Complete the first round beyond the normal limit.", ENDLESS),
		_data(&"endless_double_max", "DOUBLE OR NOTHING", "Reach twice the normal round limit in Endless Mode.", ENDLESS),
		_data(&"all_bonuses_discovered", "BONUS COLLECTOR", "Obtain every enabled bonus at least once.", BONUSES_RULES),
		_data(&"beat_all_special_rules", "RULEBOOK COMPLETE", "Beat every enabled Special Rule at least once.", BONUSES_RULES),
		_data(&"one_bonus_max_level", "FULLY UPGRADED", "Raise a bonus to its maximum level.", BONUSES_RULES),
		_data(&"all_bonuses_maxed_once", "MAXIMUM BUILD", "Max out every available bonus across your runs.", BONUSES_RULES, true),
		_data(&"beat_two_special_rules", "DOUBLE TROUBLE", "Beat a round with at least two Special Rules.", BONUSES_RULES),
		_data(&"beat_max_special_rules", "TOTAL CHAOS", "Beat a round with the maximum number of Special Rules.", BONUSES_RULES),
		_data(&"five_different_bonuses", "BUILD COMPLETE", "Own five different bonuses in one run.", BONUSES_RULES),
		_data(&"double_down_deja_vu_combo", "ECHO CHAMBER", "Trigger Double Down and Deja Vu from the same hand.", COMBOS),
		_data(&"three_bonus_combo", "EVERYONE'S HERE", "Trigger Bring a Friend, Double Down and Deja Vu from the same hand.", COMBOS, true),
		_data(&"double_down_full_activation", "DOWN THE LINE", "Use every possible Double Down placement in one activation.", COMBOS),
		_data(&"deja_vu_full_activation", "SEEING TRIPLE", "Use every possible Deja Vu placement in one activation.", COMBOS),
		_data(&"bring_a_friend_full_activation", "THE WHOLE GANG", "Successfully play every companion with Bring a Friend III.", COMBOS),
		_data(&"speedrun_10_rounds", "QUICK TEN", "Complete 10 rounds in under 5 minutes.", SPEEDRUN),
		_data(&"speedrun_20_rounds", "TEN-MINUTE TWENTY", "Complete 20 rounds in under 10 minutes.", SPEEDRUN),
		_data(&"speedrun_full_game", "THIRTY-MINUTE COUNTDOWN", "Complete the game in under 30 minutes.", SPEEDRUN, true),
	]


static func _data(
	id: StringName,
	title: String,
	description: String,
	category: StringName,
	hidden := false,
	reward_font: StringName = &""
) -> AchievementData:
	return AchievementData.new(
		id, title, description, category, hidden, reward_font
	)

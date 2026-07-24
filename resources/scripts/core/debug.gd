class_name DebugSettings
extends RefCounted

# Master switch. Every option below is ignored while this is false.
const ENABLED := true

# Mistakes still play their feedback, but never consume a life.
const GOD_MODE := false

# Progression round shown when starting a new game, from 1 to TOTAL_ROUNDS.
const START_AT_ROUND := 49

# Keep empty for normal rule selection. Add several ids to lock a combination.
# Valid ids:
# shell_game, merry_go_stack, free_range_cards, pile_up, lights_out,
# peek_a_card, stack_attack, roman_holiday.
const LOCK_SPECIAL_RULES: Array[StringName] = [
	"lights_out"
]


static func is_enabled() -> bool:
	return ENABLED


static func is_god_mode_enabled() -> bool:
	return ENABLED and GOD_MODE


static func get_start_round(total_rounds: int) -> int:
	if not ENABLED:
		return 1
	return clampi(START_AT_ROUND, 1, total_rounds)


static func get_locked_special_rules() -> Array[StringName]:
	if not ENABLED:
		return []
	var locked_rules: Array[StringName] = []
	locked_rules.assign(LOCK_SPECIAL_RULES)
	return locked_rules

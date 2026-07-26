class_name DebugSettings
extends RefCounted

# Master switch. Every option below is ignored while this is false.
const ENABLED := false

# Mistakes still play their feedback, but never consume a life.
const GOD_MODE := false

# Progression round shown when starting a new game, from 1 to TOTAL_ROUNDS.
const START_AT_ROUND := 1

# Shows the endless-mode button without requiring a completed normal run.
const UNLOCK_ENDLESS_MODE := true

# Keep empty for normal rule selection. Debug locks bypass incompatibilities,
# required-rule constraints and minimum rounds so any combination can be tested.
# Valid ids:
# shell_game, merry_go_stack, free_range_cards, pile_up, lights_out,
# peek_a_card, stack_attack, roman_holiday, musical_stacks, sticky_fingers,
# hot_potatoes, blind_delivery, mirror_match, sudden_death, grace_period,
# colorblind, floor_is_lava.
const LOCK_SPECIAL_RULES: Array[StringName] = [
	#"mirror_match",
	#"merry_go_stack",
	#"grace_period"
]

# Bonuses granted at the start of every debug run. The value is the locked
# level, clamped to the bonus maximum. Comment a line to disable that bonus.
# Valid ids:
# open_book, quick_peek, last_reminder, mistake_reveal, wild_card, redraw,
# lucky_hand, time_bank, slow_start, spare_life, safety_net, clean_slate,
# bring_a_friend, pile_mover, double_down, deja_vu, rule_breaker, adaptation.
const LOCK_BONUSES: Dictionary = {
	&"pile_mover": 1,
	#&"bring_a_friend": 3,
	#&"double_down": 3,
	#&"deja_vu":3,
}

static var _runtime_god_mode := GOD_MODE


static func is_enabled() -> bool:
	return ENABLED


static func is_god_mode_enabled() -> bool:
	return ENABLED and _runtime_god_mode


static func toggle_god_mode() -> bool:
	if not ENABLED:
		return false
	_runtime_god_mode = not _runtime_god_mode
	return _runtime_god_mode


static func get_start_round(total_rounds: int) -> int:
	if not ENABLED:
		return 1
	return clampi(START_AT_ROUND, 1, total_rounds)


static func unlock_endless_mode() -> bool:
	return ENABLED and UNLOCK_ENDLESS_MODE


static func get_locked_special_rules() -> Array[StringName]:
	if not ENABLED:
		return []
	var locked_rules: Array[StringName] = []
	locked_rules.assign(LOCK_SPECIAL_RULES)
	return locked_rules


static func get_locked_bonuses() -> Dictionary:
	if not ENABLED:
		return {}
	return LOCK_BONUSES.duplicate()

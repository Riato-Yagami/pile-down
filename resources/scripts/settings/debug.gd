class_name DebugSettings
extends RefCounted

# Master switch. Every option below is ignored while this is false.
const ENABLED := true

# Mistakes still play their feedback, but never consume a life.
const GOD_MODE := false

# Progression round shown when starting a new game, from 1 to TOTAL_ROUNDS.
const START_AT_ROUND := 1

# Shows the endless-mode button without requiring a completed normal run.
const UNLOCK_ENDLESS_MODE := true
const UNLOCK_ALL_CHECKPOINTS := false
const START_FROM_CHECKPOINT := 0
const UNLOCK_ALL_ACHIEVEMENTS := false
const UNLOCK_ALL_FONTS := false
const DISCOVER_ALL_BONUSES := false
const DISCOVER_ALL_SPECIAL_RULES := false
const FORCE_WAVY_BABY := false
const FORCE_SHAKING_PILES := false
const SHOW_DUST_DEBUG := false

# Keep empty for normal rule selection. Debug locks bypass incompatibilities,
# required-rule constraints and minimum rounds so any combination can be tested.
# Valid ids:
# shell_game, merry_go_stack, free_range_cards, pile_up, lights_out,
# peek_a_card, stack_attack, roman_holiday, musical_stacks, sticky_fingers,
# hot_potatoes, blind_delivery, mirror_match, sudden_death, grace_period,
# colorblind, floor_is_lava, pixelated, shaking_piles, wavy_baby.
const LOCK_SPECIAL_RULES: Array[StringName] = [
	"pixelated",
	#"wavy_baby",
	#"shaking_piles",
	#"lights_out",
	#"shell_game",
	#"musical_stacks"
	#"pixelated"
]

# Bonuses granted at the start of every debug run. A positive value locks the
# normal level. A negative value keeps the matching level statistics but forces
# chance-based activations to 100% (-1 = level 1, -2 = level 2, and so on).
# Levels are clamped to the bonus maximum. Comment a line to disable that bonus.
# Valid ids:
# open_book, quick_peek, last_reminder, mistake_reveal, wild_card, redraw,
# lucky_hand, time_bank, slow_start, spare_life, safety_net, clean_slate,
# bring_a_friend, pile_mover, double_down, deja_vu, rule_breaker, adaptation.
const LOCK_BONUSES: Dictionary = {
	&"lucky_hand": 1,
	&"bring_a_friend": 3,
	&"pile_mover":1,
	#&"double_down": 3,
	&"deja_vu":2,
}

static var _runtime_god_mode := GOD_MODE
static var _runtime_unlock_everything := false


static func is_enabled() -> bool:
	return ENABLED


static func is_god_mode_enabled() -> bool:
	return ENABLED and _runtime_god_mode


static func toggle_god_mode() -> bool:
	if not ENABLED:
		return false
	_runtime_god_mode = not _runtime_god_mode
	return _runtime_god_mode


static func is_unlock_everything_enabled() -> bool:
	return ENABLED and _runtime_unlock_everything


static func toggle_unlock_everything() -> bool:
	if not ENABLED:
		return false
	_runtime_unlock_everything = not _runtime_unlock_everything
	return _runtime_unlock_everything


static func get_start_round(total_rounds: int) -> int:
	if not ENABLED:
		return 1
	return clampi(START_AT_ROUND, 1, total_rounds)


static func unlock_endless_mode() -> bool:
	return ENABLED and (UNLOCK_ENDLESS_MODE or _runtime_unlock_everything)


static func unlock_all_checkpoints() -> bool:
	return ENABLED and (UNLOCK_ALL_CHECKPOINTS or _runtime_unlock_everything)


static func is_dust_debug_visible() -> bool:
	return ENABLED and SHOW_DUST_DEBUG


static func start_from_checkpoint() -> int:
	return START_FROM_CHECKPOINT if ENABLED else 0


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

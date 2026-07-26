class_name DifficultySettings
extends RefCounted

# Starting values.
const START_PILES := 1
const START_HAND_SIZE := 1
const START_CARD_VALUE := 3
const START_TURN_TIME := 5.0

# Limits. Keep these aligned with the gameplay invariants.
const MAX_PILES := 25
const MAX_HAND_SIZE := 4
const MAX_CARD_VALUE := 9
const MIN_TURN_TIME := 3.0

# The counter starts here and reaches zero after this many cleared rounds.
const TOTAL_ROUNDS := 50

# Relative weights used after the first cleared round.
# A weight of 0 disables an option. The values do not need to add up to 100.
const ADD_PILE_WEIGHT := 35.0
const ADD_CARD_WEIGHT := 25.0
const ADD_START_VALUE_WEIGHT := 15.0
const REDUCE_TURN_TIME_WEIGHT := 5.0
const NO_DIFFICULTY_CHANGE_WEIGHT := 10.0

# The first round uses these pile/card weights independently from the regular
# weights above. NO_DIFFICULTY_CHANGE_WEIGHT remains available.
const FIRST_ADD_PILE_WEIGHT := 70.0
const FIRST_ADD_CARD_WEIGHT := 30.0

# Special Rules.
# Comment a line to remove that rule from every automatic selection.
const ENABLED_SPECIAL_RULES: Array[StringName] = [
	&"shell_game",
	&"merry_go_stack",
	&"free_range_cards",
	&"pile_up",
	&"lights_out",
	&"peek_a_card",
	&"stack_attack",
	&"roman_holiday",
	&"musical_stacks",
	&"sticky_fingers",
	&"hot_potatoes",
	&"blind_delivery",
	&"mirror_match",
	&"sudden_death",
	&"grace_period",
	&"colorblind",
	#&"floor_is_lava",
]

const FIRST_SPECIAL_RULE_ROUND := 4
const EXTRA_SPECIAL_RULE_CHANCE := 0.75
const MAX_COMBINED_RULES := 5
const THREE_PILE_SHELL_GAME_ROUND := 30
const REGENERATING_PILE_RATIO := 0.35
const REGENERATION_DURATION := 8.0
const LIGHTS_OUT_RADIUS := 60.0
const HOT_POTATO_DURATION := 1
const STICKY_HOT_POTATO_DURATION := 2
# During Grace Period, reveal the running clock this many seconds before expiry.
const GRACE_PERIOD_REVEAL_TIME := 1.25

# Mirror Match variants. These are relative weights and do not need to total 100.
const MIRROR_HORIZONTAL_WEIGHT := 75.0
const MIRROR_VERTICAL_WEIGHT := 20.0
const MIRROR_BOTH_AXES_WEIGHT := 5.0


static func special_rule_milestone(rule_count: int) -> int:
	return (FIRST_SPECIAL_RULE_ROUND + rule_count - 1) * rule_count


static func is_special_rule_enabled(rule_id: StringName) -> bool:
	return ENABLED_SPECIAL_RULES.has(rule_id)

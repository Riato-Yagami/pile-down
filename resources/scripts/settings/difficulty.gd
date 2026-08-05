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

#const MAX_PILES := 1
#const MAX_HAND_SIZE := 1
#const MAX_CARD_VALUE := 2
#const MIN_TURN_TIME := 3.0

# The counter starts here and reaches zero after this many cleared rounds.
const TOTAL_ROUNDS := 50

# Relative weights used after the first cleared round.
# A weight of 0 disables an option. The values do not need to add up to 100.
const ADD_PILE_WEIGHT := 35.0
const ADD_CARD_WEIGHT := 25.0
const ADD_START_VALUE_WEIGHT := 15.0
const REDUCE_TURN_TIME_WEIGHT := 5.0
const NO_DIFFICULTY_CHANGE_WEIGHT := 10.0

const STAT_PITY_RATE := 0.25
const MAX_STAT_DROUGHT := 5
const STARTER_STAT_MULTIPLIER := 2.0

# Permanent progression checkpoints use the internal, increasing round number.
const CHECKPOINT_INTERVAL := 2
const ENABLE_CHECKPOINTS := true

# The first round uses these pile/card weights independently from the regular
# weights above. NO_DIFFICULTY_CHANGE_WEIGHT remains available.
const FIRST_ADD_PILE_WEIGHT := 70.0
const FIRST_ADD_CARD_WEIGHT := 30.0

# Special Rules.
# Comment a line to remove that rule from every automatic selection.
const ENABLED_SPECIAL_RULES: Array[StringName] = [
	&"shell_game",
	&"merry_go_stack",
	&"shaking_piles",
	&"wavy_baby",
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

# Continuous pile movement rules, tuned for the native 256 x 320 viewport.
const MERRY_GO_STACK_SPEED := 0.35
const MERRY_GO_STACK_SETUP_DURATION := 0.45
const MERRY_GO_STACK_MINIMUM_RADIUS := 58.0
const MERRY_GO_STACK_RADIUS_PADDING := 4.0
const SHAKING_PILES_AMPLITUDE_X := 1.0
const SHAKING_PILES_AMPLITUDE_Y := 1.0
const SHAKING_PILES_FREQUENCY_X := 10
const SHAKING_PILES_FREQUENCY_Y := 10
const SHAKING_PILES_PHASE_STEP_X := 1.73
const SHAKING_PILES_PHASE_STEP_Y := 2.31
const MOVING_PILES_SAFETY_SEARCH_ITERATIONS := 10
const MOVING_PILES_VISUAL_GAP := 2.0
const WAVY_BABY_AMPLITUDE := 12.0
const WAVY_BABY_SPEED := 1.6
const WAVY_BABY_PHASE := 0.0
const WAVY_BABY_HORIZONTAL_PHASE_SPACING := 0.06

# Mirror Match variants. These are relative weights and do not need to total 100.
const MIRROR_HORIZONTAL_WEIGHT := 75.0
const MIRROR_VERTICAL_WEIGHT := 20.0
const MIRROR_BOTH_AXES_WEIGHT := 5.0


static func special_rule_milestone(rule_count: int) -> int:
	return (FIRST_SPECIAL_RULE_ROUND + rule_count - 1) * rule_count


static func is_special_rule_enabled(rule_id: StringName) -> bool:
	return ENABLED_SPECIAL_RULES.has(rule_id)


# Persistent run bonuses.
# Keep every bonus gameplay setting in this final section so the complete
# balance can be adjusted without searching through gameplay scripts.
# Comment a line to remove that bonus from every automatic selection. Debug
# locks still bypass this list, just like LOCK_SPECIAL_RULES.
const ENABLED_BONUSES: Array[StringName] = [
	&"open_book",
	&"quick_peek",
	&"last_reminder",
	&"mistake_reveal",
	&"wild_card",
	&"redraw",
	&"lucky_hand",
	&"time_bank",
	&"slow_start",
	&"spare_life",
	&"safety_net",
	&"clean_slate",
	&"bring_a_friend",
	&"pile_mover",
	&"double_down",
	&"deja_vu",
	&"rule_breaker",
	&"adaptation",
]

const BONUS_INTERVAL := 4
const BONUS_CHOICE_COUNT := 2
const MAX_ACTIVE_BONUS_TYPES := 999

const QUICK_PEEK_HAND_INTERVALS: Array[int] = [4, 3, 2]
const QUICK_PEEK_DURATIONS: Array[float] = [0.10, 0.20, 0.25]
const MISTAKE_REVEAL_DURATIONS := [0.0, 0.25, 0.4, 0.6]

const TOUCH_PEEK_DRAG_DELAY := 0.12
const TOUCH_PEEK_VISIBLE_GRACE := 0.18
const TOUCH_DRAG_DISTANCE := 5.0

const DUST_PARTICLE_COUNT := 48

const WILD_CARD_CHANCES := [0.0, 0.05, 0.1, 0.15]
const LUCKY_HAND_CHANCES := [0.0, 0.2, 0.35, 0.45]
const REDRAW_COUNTS := [0, 1, 2, 3]

const TIME_BANK_RATES := [0.0, 0.2, 0.35, 0.5]
const TIME_BANK_MAXIMUM := 2.0
const WARM_UP_HANDS_PER_TIER := 3

const SPARE_LIFE_COUNTS := [0, 1, 2, 3]
const CLEAN_SLATE_USES := [0, 1, 2, 2]
const CLEAN_SLATE_FULL_RESTORE_LEVEL := 3

const ADAPTATION_MULTIPLIERS := [1.0, 0.8, 0.7, 0.6]
const RULE_BREAKER_DELETION_COUNTS := [0, 1, 1, 2]
const RULE_BREAKER_DELETE_LAST_MINIMUM_LEVEL := 2
const MINIMUM_PILE_DISTANCE := 44.0
const AUTOMATIC_PLACEMENT_DURATION := 0.14
const BONUS_CHAIN_PLACEMENT_DURATION := 0.32
# The regular board step is 44 px. This reaches north/south/east/west
# neighbours while leaving the 62 px corner-to-corner diagonal outside.
const BRING_A_FRIEND_NEIGHBOR_RADIUS := 56.0


static func is_bonus_enabled(bonus_id: StringName) -> bool:
	return ENABLED_BONUSES.has(bonus_id)

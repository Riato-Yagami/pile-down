class_name DifficultySettings
extends RefCounted

# Starting values.
const START_PILES := 1
const START_HAND_SIZE := 1
const START_CARD_VALUE := 5
const START_TURN_TIME := 5.0

# Limits. Keep these aligned with the gameplay invariants.
const MAX_PILES := 25
const MAX_HAND_SIZE := 3
const MAX_CARD_VALUE := 9
const MIN_TURN_TIME := 2.0

# The counter starts here and reaches zero after this many cleared rounds.
const TOTAL_ROUNDS := 100

# Relative weights used after the first cleared round.
# A weight of 0 disables an option. The values do not need to add up to 100.
const ADD_PILE_WEIGHT := 55.0
const ADD_CARD_WEIGHT := 25.0
const ADD_START_VALUE_WEIGHT := 10.0
const REDUCE_TURN_TIME_WEIGHT := 5.0

# The first upgrade is always a pile or a card. These two weights control
# that first choice independently from the regular weights above.
const FIRST_ADD_PILE_WEIGHT := 55.0
const FIRST_ADD_CARD_WEIGHT := 25.0

# Special Rules.
const SPECIAL_RULE_FREQUENCY := 5
const SPECIAL_RULE_START_ROUND := 4
const EXTRA_SPECIAL_RULE_CHANCE := 0.75
const MAX_COMBINED_RULES := 5
const HARD_COMBO_MINIMUM_ROUND := 25
const THREE_PILE_SHELL_GAME_ROUND := 30
const REGENERATING_PILE_RATIO := 0.35
const REGENERATION_DURATION := 8.0

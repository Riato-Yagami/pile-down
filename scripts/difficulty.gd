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
const ADD_CARD_WEIGHT := 20.0
const ADD_START_VALUE_WEIGHT := 20.0
const REDUCE_TURN_TIME_WEIGHT := 5.0

# The first upgrade is always a pile or a card. These two weights control
# that first choice independently from the regular weights above.
const FIRST_ADD_PILE_WEIGHT := 55.0
const FIRST_ADD_CARD_WEIGHT := 20.0

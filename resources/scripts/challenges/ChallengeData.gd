class_name ChallengeData
extends Data

@export var title: String
@export var description: String
@export var required_achievement: AchievementData
# Legacy identifier kept so old programmatic resources and callers remain valid.
var unlock_achievement: StringName
@export var start_round := 5
@export var target_round := 20
@export var allow_endless := true
@export_category("Starting Difficulty")
# A negative value keeps the difficulty simulated from start_round.
@export_range(-1, 25, 1) var starting_pile_count := -1
@export_range(-1, 4, 1) var starting_hand_size := -1
@export_range(-1, 9, 1) var starting_card_value := -1
@export_range(-1.0, 60.0, 0.5) var starting_turn_time := -1.0
@export_category("Gameplay Modifiers")
@export var guarantee_playable_hand := true
## Added when a challenge reload is used with less than one second remaining.
@export_range(0.0, 60.0, 0.1, "suffix:s") var reload_low_time_bonus := 2.0
@export var force_single_life := false
@export var disable_life_bonuses := false
@export var pool_physics_enabled := false
@export var hide_tile_numbers := false
@export var shared_round_clock := false
## Negative uses the current normal hand timer for the round estimate.
@export_range(-1.0, 60.0, 0.5) var shared_clock_seconds_per_hand := -1.0
@export var conveyor_hand := false
@export var conveyor_guaranteed_interval := 0
## Negative uses Difficulty.CONVEYOR_BASE_SPEED.
@export_range(-1.0, 100.0, 1.0) var conveyor_speed := -1.0
## Gives the player one setup round before challenge special rules can appear.
@export var disable_special_rules_on_first_round := true
@export var force_special_rules_every_round := false
@export var forced_special_rule_count := 0
@export var commit_selected_cards := false
@export var hide_selected_card_value := false
@export_category("Bonuses and Special Rules")
@export var forced_bonuses: Dictionary = {}
@export var disabled_bonuses: Array[StringName] = []
@export var forced_rules: Array[StringName] = []
@export var disabled_rules: Array[StringName] = []


func _init(
	challenge_id: StringName = &"",
	challenge_title := "",
	challenge_description := "",
	achievement: StringName = &"",
	challenge_start_round := 5,
	challenge_target_round := 20
) -> void:
	id = challenge_id
	title = challenge_title
	description = challenge_description
	unlock_achievement = achievement
	start_round = challenge_start_round
	target_round = challenge_target_round


func required_achievement_id() -> StringName:
	if required_achievement != null:
		return required_achievement.id
	return unlock_achievement

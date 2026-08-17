class_name ChallengeModifiers
extends RefCounted

var guarantee_playable_hand := true
var reload_low_time_bonus := 2.0
var force_single_life := false
var disable_life_bonuses := false
var pool_physics_enabled := false
var hide_tile_numbers := false
var shared_round_clock := false
var shared_clock_seconds_per_hand := -1.0
var conveyor_hand := false
var conveyor_guaranteed_interval := 0
var conveyor_speed := -1.0
var disable_special_rules_on_first_round := true
var force_special_rules_every_round := false
var forced_special_rule_count := 0
var commit_selected_cards := false
var hide_selected_card_value := false
var disabled_special_rules: Array[StringName] = []
var disabled_bonuses: Array[StringName] = []

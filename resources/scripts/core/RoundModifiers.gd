class_name RoundModifiers
extends RefCounted

enum StackDirection {
	DOWN,
	UP,
}

var stack_direction := StackDirection.DOWN
var swap_piles_after_play := false
var moving_pile_pattern := false
var moving_pile_pattern_id: StringName = &""
var wandering_hand_cards := false
var flashlight_enabled := false
var hover_reveal_enabled := false
var regeneration_enabled := false
var roman_numerals_enabled := false
var musical_stacks_enabled := false
var sticky_fingers_enabled := false
var hot_potatoes_enabled := false
var blind_delivery_enabled := false
var mirror_match_enabled := false
var mirror_horizontal := false
var mirror_vertical := false
var sudden_death_enabled := false
var grace_period_enabled := false
var colorblind_enabled := false
var floor_is_lava_enabled := false

var maximum_mistakes_override := -1
var grace_period_duration := 0.0
var hot_potato_drag_duration := 0.0
var musical_stacks_direction := 1
var special_rule_intensity_multiplier := 1.0


func reset() -> void:
	stack_direction = StackDirection.DOWN
	swap_piles_after_play = false
	moving_pile_pattern = false
	moving_pile_pattern_id = &""
	wandering_hand_cards = false
	flashlight_enabled = false
	hover_reveal_enabled = false
	regeneration_enabled = false
	roman_numerals_enabled = false
	musical_stacks_enabled = false
	sticky_fingers_enabled = false
	hot_potatoes_enabled = false
	blind_delivery_enabled = false
	mirror_match_enabled = false
	mirror_horizontal = false
	mirror_vertical = false
	sudden_death_enabled = false
	grace_period_enabled = false
	colorblind_enabled = false
	floor_is_lava_enabled = false
	maximum_mistakes_override = -1
	grace_period_duration = 0.0
	hot_potato_drag_duration = 0.0
	musical_stacks_direction = 1
	special_rule_intensity_multiplier = 1.0


static func format_value(value: int, use_roman_numerals: bool) -> String:
	if not use_roman_numerals:
		return str(value)
	const ROMAN_VALUES := ["O", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
	return ROMAN_VALUES[value] if value >= 0 and value < ROMAN_VALUES.size() else str(value)


static func value_font_size(value: int, use_roman_numerals: bool) -> int:
	return 14 if use_roman_numerals and value in [7, 8] else 20

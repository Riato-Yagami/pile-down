class_name RoundModifiers
extends RefCounted

enum StackDirection {
	DOWN,
	UP,
}

var stack_direction := StackDirection.DOWN
var swap_piles_after_play := false
var moving_pile_pattern := false
var wandering_hand_cards := false
var flashlight_enabled := false
var hover_reveal_enabled := false
var regeneration_enabled := false
var roman_numerals_enabled := false


func reset() -> void:
	stack_direction = StackDirection.DOWN
	swap_piles_after_play = false
	moving_pile_pattern = false
	wandering_hand_cards = false
	flashlight_enabled = false
	hover_reveal_enabled = false
	regeneration_enabled = false
	roman_numerals_enabled = false


static func format_value(value: int, use_roman_numerals: bool) -> String:
	if not use_roman_numerals:
		return str(value)
	const ROMAN_VALUES := ["O", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
	return ROMAN_VALUES[value] if value >= 0 and value < ROMAN_VALUES.size() else str(value)


static func value_font_size(value: int, use_roman_numerals: bool) -> int:
	return 14 if use_roman_numerals and value in [7, 8] else 20

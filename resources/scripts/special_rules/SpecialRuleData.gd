class_name SpecialRuleData
extends RefCounted

var id: StringName
var title: String
var subtitle: String
var incompatible_rules: Array[StringName] = []
var required_rules: Array[StringName] = []
var weight := 1.0
var minimum_round := 1


func _init(
	rule_id: StringName,
	rule_title: String,
	rule_subtitle: String,
	incompatible: Array[StringName] = [],
	required: Array[StringName] = [],
	rule_weight := 1.0,
	rule_minimum_round := 1
) -> void:
	id = rule_id
	title = rule_title
	subtitle = rule_subtitle
	incompatible_rules = incompatible
	required_rules = required
	weight = rule_weight
	minimum_round = rule_minimum_round


func activate(context: RoundContext) -> void:
	match id:
		&"shell_game":
			context.modifiers.swap_piles_after_play = true
		&"merry_go_stack":
			context.modifiers.moving_pile_pattern = true
		&"free_range_cards":
			context.modifiers.wandering_hand_cards = true
		&"pile_up":
			context.modifiers.stack_direction = RoundModifiers.StackDirection.UP
		&"lights_out":
			context.modifiers.flashlight_enabled = true
		&"peek_a_card":
			context.modifiers.hover_reveal_enabled = true
		&"stack_attack":
			context.modifiers.regeneration_enabled = true
		&"roman_holiday":
			context.modifiers.roman_numerals_enabled = true


func deactivate(context: RoundContext) -> void:
	match id:
		&"shell_game":
			context.modifiers.swap_piles_after_play = false
		&"merry_go_stack":
			context.modifiers.moving_pile_pattern = false
		&"free_range_cards":
			context.modifiers.wandering_hand_cards = false
		&"pile_up":
			context.modifiers.stack_direction = RoundModifiers.StackDirection.DOWN
		&"lights_out":
			context.modifiers.flashlight_enabled = false
		&"peek_a_card":
			context.modifiers.hover_reveal_enabled = false
		&"stack_attack":
			context.modifiers.regeneration_enabled = false
		&"roman_holiday":
			context.modifiers.roman_numerals_enabled = false

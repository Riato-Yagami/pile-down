class_name SpecialRuleData
extends SpecialRule

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")


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
			context.modifiers.moving_pile_pattern_id = &"orbit"
		&"shaking_piles":
			context.modifiers.moving_pile_pattern = true
			context.modifiers.moving_pile_pattern_id = &"shake"
		&"wavy_baby":
			context.modifiers.moving_pile_pattern = true
			context.modifiers.moving_pile_pattern_id = &"wave"
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
		&"musical_stacks":
			context.modifiers.musical_stacks_enabled = true
			context.modifiers.musical_stacks_direction = (
				-1 if context.rng.randi() % 2 == 0 else 1
			)
		&"sticky_fingers":
			context.modifiers.sticky_fingers_enabled = true
			if context.modifiers.hot_potatoes_enabled:
				context.modifiers.hot_potato_drag_duration = (
					Difficulty.STICKY_HOT_POTATO_DURATION
				)
		&"hot_potatoes":
			context.modifiers.hot_potatoes_enabled = true
			context.modifiers.hot_potato_drag_duration = (
				Difficulty.STICKY_HOT_POTATO_DURATION
				if context.modifiers.sticky_fingers_enabled
				else Difficulty.HOT_POTATO_DURATION
			)
		&"blind_delivery":
			context.modifiers.blind_delivery_enabled = true
		&"mirror_match":
			context.modifiers.mirror_match_enabled = true
			var horizontal_weight := maxf(Difficulty.MIRROR_HORIZONTAL_WEIGHT, 0.0)
			var vertical_weight := maxf(Difficulty.MIRROR_VERTICAL_WEIGHT, 0.0)
			var both_axes_weight := maxf(Difficulty.MIRROR_BOTH_AXES_WEIGHT, 0.0)
			var total_weight := horizontal_weight + vertical_weight + both_axes_weight
			var mirror_roll := context.rng.randf_range(0.0, total_weight)
			if total_weight <= 0.0 or mirror_roll < horizontal_weight:
				context.modifiers.mirror_horizontal = true
				context.modifiers.mirror_vertical = false
			elif mirror_roll < horizontal_weight + vertical_weight:
				context.modifiers.mirror_horizontal = false
				context.modifiers.mirror_vertical = true
			else:
				context.modifiers.mirror_horizontal = true
				context.modifiers.mirror_vertical = true
		&"sudden_death":
			context.modifiers.sudden_death_enabled = true
			context.modifiers.maximum_mistakes_override = 1
		&"grace_period":
			context.modifiers.grace_period_enabled = true
		&"colorblind":
			context.modifiers.colorblind_enabled = true
		&"floor_is_lava":
			context.modifiers.floor_is_lava_enabled = true
		&"pixelated":
			context.modifiers.pixelation_enabled = true


func deactivate(context: RoundContext) -> void:
	match id:
		&"shell_game":
			context.modifiers.swap_piles_after_play = false
		&"merry_go_stack":
			context.modifiers.moving_pile_pattern = false
			context.modifiers.moving_pile_pattern_id = &""
		&"shaking_piles", &"wavy_baby":
			context.modifiers.moving_pile_pattern = false
			context.modifiers.moving_pile_pattern_id = &""
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
		&"musical_stacks":
			context.modifiers.musical_stacks_enabled = false
		&"sticky_fingers":
			context.modifiers.sticky_fingers_enabled = false
			if context.modifiers.hot_potatoes_enabled:
				context.modifiers.hot_potato_drag_duration = (
					Difficulty.HOT_POTATO_DURATION
				)
		&"hot_potatoes":
			context.modifiers.hot_potatoes_enabled = false
			context.modifiers.hot_potato_drag_duration = 0.0
		&"blind_delivery":
			context.modifiers.blind_delivery_enabled = false
		&"mirror_match":
			context.modifiers.mirror_match_enabled = false
			context.modifiers.mirror_horizontal = false
			context.modifiers.mirror_vertical = false
		&"sudden_death":
			context.modifiers.sudden_death_enabled = false
			context.modifiers.maximum_mistakes_override = -1
		&"grace_period":
			context.modifiers.grace_period_enabled = false
			context.modifiers.grace_period_duration = 0.0
		&"colorblind":
			context.modifiers.colorblind_enabled = false
		&"floor_is_lava":
			context.modifiers.floor_is_lava_enabled = false
		&"pixelated":
			context.modifiers.pixelation_enabled = false

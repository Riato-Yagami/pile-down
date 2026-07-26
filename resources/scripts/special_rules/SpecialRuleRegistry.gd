class_name SpecialRuleRegistry
extends RefCounted

const RuleData := preload("res://resources/scripts/special_rules/SpecialRuleData.gd")


static func create_all_rules() -> Array[SpecialRuleData]:
	var rules: Array[SpecialRuleData] = [
		RuleData.new(&"shell_game", "SHELL GAME", "Now you see it..."),
		RuleData.new(&"merry_go_stack", "MERRY-GO-STACK", "Please remain seated."),
		RuleData.new(&"free_range_cards", "FREE-RANGE CARDS", "They escaped again."),
		RuleData.new(&"pile_up", "PILE UP", "Wrong way. Keep going."),
		RuleData.new(
			&"lights_out",
			"LIGHTS OUT",
			"Hope you brought a mouse.",
			[&"shell_game", &"merry_go_stack"]
		),
		RuleData.new(
			&"peek_a_card",
			"PEEK-A-CARD",
			"No peeking. Except peeking.",
			[]
		),
		RuleData.new(&"stack_attack", "STACK ATTACK", "Progress is temporary."),
		RuleData.new(&"roman_holiday", "ROMAN HOLIDAY", "When in Rome..."),
		RuleData.new(
			&"musical_stacks",
			"MUSICAL STACKS",
			"Everybody switch seats.",
			[&"shell_game", &"merry_go_stack"],
			[],
			1.0
		),
		RuleData.new(
			&"sticky_fingers",
			"STICKY FINGERS",
			"No take-backs.",
			[],
			[],
			0.8
		),
		RuleData.new(
			&"hot_potatoes",
			"HOT POTATOES",
			"Keep it moving.",
			[],
			[],
			1.0
		),
		RuleData.new(
			&"blind_delivery",
			"BLIND DELIVERY",
			"Remember the package.",
			[],
			[],
			0.9
		),
		RuleData.new(
			&"mirror_match",
			"MIRROR MATCH",
			"Turn the whole picture around.",
			[],
			[],
			0.8
		),
		RuleData.new(
			&"sudden_death",
			"SUDDEN DEATH",
			"One mistake. That's all.",
			[],
			[],
			0.5,
			10
		),
		RuleData.new(
			&"grace_period",
			"GRACE PERIOD",
			"The deadline is a surprise.",
			[],
			[],
			1.0
		),
		RuleData.new(
			&"colorblind",
			"COLORBLIND",
			"Fifty shades of stack.",
			[],
			[],
			1.1
		),
		RuleData.new(
			&"floor_is_lava",
			"THE FLOOR IS LAVA",
			"Obviously.",
			[],
			[],
			0.8,
			10
		),
	]
	return rules

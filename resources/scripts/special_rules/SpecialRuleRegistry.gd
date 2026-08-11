class_name SpecialRuleRegistry
extends RefCounted

const RuleData := preload("res://resources/scripts/special_rules/SpecialRuleData.gd")


static func create_all_rules() -> Array[SpecialRuleData]:
	var rules: Array[SpecialRuleData] = [
		RuleData.new(&"shell_game", "SHELL GAME", "Now you see it..."),
		RuleData.new(
			&"merry_go_stack", "MERRY-GO-STACK", "Please remain seated.",
			[&"shaking_piles", &"wavy_baby"]
		),
		RuleData.new(
			&"shaking_piles", "SHAKING PILES", "Please remain unstable.",
			[&"merry_go_stack", &"wavy_baby"], [], 0.9, 6
		),
		RuleData.new(
			&"wavy_baby", "WAVY BABY", "Go with the flow.",
			[&"merry_go_stack", &"shaking_piles"], [], 0.8, 8
		),
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
			[&"merry_go_stack", &"shaking_piles", &"wavy_baby"],
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
		RuleData.new(
			&"pixelated",
			"PIXELATED",
			"Now with fewer pixels.",
			[],
			[],
			0.8,
			8
		),
	]
	var effect_descriptions := {
		&"shell_game": "Piles swap positions after each correct card.",
		&"merry_go_stack": "Piles orbit continuously around the center pile.",
		&"shaking_piles": "Every pile shakes around its normal position.",
		&"wavy_baby": "A continuous wave moves through all the piles.",
		&"free_range_cards": "Cards wander across the screen instead of staying put.",
		&"pile_up": "Piles count upward and accept the next higher value.",
		&"lights_out": "Darkness covers the board except around your pointer.",
		&"peek_a_card": "Hidden cards reveal when hovered or first touched.",
		&"stack_attack": "Some piles regain progress if their timer expires.",
		&"roman_holiday": "All card and pile values use Roman numerals.",
		&"musical_stacks": "Remaining piles rotate after every correct card.",
		&"sticky_fingers": "A released card stays attached until it is placed.",
		&"hot_potatoes": "Held cards return to the hand when drag time runs out.",
		&"blind_delivery": "A card becomes hidden while you drag it.",
		&"mirror_match": "Cards and piles are mirrored on one or both axes.",
		&"sudden_death": "You have only one mistake for the round.",
		&"grace_period": "The timer disappears shortly before it expires.",
		&"colorblind": "Cards and piles lose their identifying colors.",
		&"floor_is_lava": "Cards touching the lava zone return to your hand.",
		&"pixelated": "The entire gameplay screen is rendered in large pixel blocks.",
	}
	for rule in rules:
		rule.description = str(effect_descriptions.get(rule.id, ""))
	return rules

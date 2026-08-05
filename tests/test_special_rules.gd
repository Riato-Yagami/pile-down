extends SceneTree

const ManagerScript := preload("res://resources/scripts/special_rules/SpecialRuleManager.gd")
const AnnouncementScript := preload(
	"res://resources/scripts/special_rules/SpecialRuleAnnouncement.gd"
)


func _init() -> void:
	var manager := ManagerScript.new() as SpecialRuleManager
	for rule in manager._rules:
		assert(not rule.description.is_empty())
		assert(rule.description != rule.subtitle)
	for enabled_rule_id in DifficultySettings.ENABLED_SPECIAL_RULES:
		assert(manager._rules.any(
			func(rule: SpecialRuleData) -> bool:
				return rule.id == enabled_rule_id
		))
	assert(DifficultySettings.FIRST_SPECIAL_RULE_ROUND == 4)
	assert(DifficultySettings.special_rule_milestone(1) == 4)
	assert(DifficultySettings.special_rule_milestone(2) == 10)
	assert(DifficultySettings.special_rule_milestone(6) == 54)
	assert(manager.get_special_rule_capacity(1) == 0)
	assert(manager.get_special_rule_capacity(3) == 0)
	assert(manager.get_special_rule_capacity(4) == 1)
	assert(manager.get_special_rule_capacity(9) == 1)
	assert(manager.get_special_rule_capacity(10) == 2)
	assert(manager.get_special_rule_capacity(17) == 2)
	assert(manager.get_special_rule_capacity(18) == 3)
	assert(manager.get_special_rule_capacity(28) == 4)
	assert(manager.get_special_rule_capacity(40) == 5)
	assert(manager.get_special_rule_capacity(100) == DifficultySettings.MAX_COMBINED_RULES)
	assert(manager.roll_rule_count(1) == 0)
	assert(manager.roll_rule_count(3) == 0)

	assert(manager.get_guaranteed_rule_count(1) == 0)
	assert(manager.get_guaranteed_rule_count(4) == 1)
	assert(manager.get_guaranteed_rule_count(10) == 2)
	assert(manager.get_guaranteed_rule_count(18) == 3)
	assert(manager.get_guaranteed_rule_count(28) == 4)
	assert(manager.get_guaranteed_rule_count(40) == 5)
	assert(manager.roll_rule_count(4) == 1)
	assert(manager.roll_rule_count(10) == 2)
	assert(manager.roll_rule_count(18) == 3)
	assert(manager.roll_rule_count(28) == 4)
	assert(manager.roll_rule_count(40) == 5)
	assert(manager._round_precedes_guaranteed_combo(9))
	assert(manager._round_precedes_guaranteed_combo(17))
	assert(not manager._round_precedes_guaranteed_combo(10))

	var debug_locks: Array[StringName] = [
		&"shell_game",
		&"merry_go_stack",
		&"roman_holiday",
		&"roman_holiday",
	]
	var debug_selection := manager._select_locked_rules(debug_locks, 1)
	assert(debug_selection.size() == 3)
	assert(debug_selection[0].id == &"shell_game")
	assert(debug_selection[1].id == &"merry_go_stack")
	assert(debug_selection[2].id == &"roman_holiday")
	var forbidden_debug_combo: Array[StringName] = [
		&"shell_game",
		&"lights_out",
	]
	var forbidden_debug_selection := manager._select_locked_rules(
		forbidden_debug_combo,
		1
	)
	assert(forbidden_debug_selection.size() == 2)
	assert(forbidden_debug_selection[0].id == &"shell_game")
	assert(forbidden_debug_selection[1].id == &"lights_out")
	var find_rule := func(id: StringName) -> SpecialRuleData:
		for rule in manager._rules:
			if rule.id == id:
				return rule
		return null
	var lights_out: SpecialRuleData = find_rule.call(&"lights_out")
	var shell_game_rules: Array[SpecialRuleData] = [find_rule.call(&"shell_game")]
	var moving_stack_rules: Array[SpecialRuleData] = [find_rule.call(&"merry_go_stack")]
	var shaking_rule: SpecialRuleData = find_rule.call(&"shaking_piles")
	var wavy_rule: SpecialRuleData = find_rule.call(&"wavy_baby")
	var shaking_rules: Array[SpecialRuleData] = [shaking_rule]
	var shell_rule: SpecialRuleData = find_rule.call(&"shell_game")
	var musical_rule: SpecialRuleData = find_rule.call(&"musical_stacks")
	var peek_rules: Array[SpecialRuleData] = [find_rule.call(&"peek_a_card")]
	var blind_delivery_rule: SpecialRuleData
	for rule in manager._rules:
		if rule.id == &"blind_delivery":
			blind_delivery_rule = rule
			break
	assert(not manager._is_compatible(lights_out, shell_game_rules))
	assert(not manager._is_compatible(lights_out, moving_stack_rules))
	assert(manager._is_compatible(lights_out, peek_rules))
	assert(manager._is_compatible(blind_delivery_rule, peek_rules))
	assert(not manager._is_compatible(shaking_rule, moving_stack_rules))
	assert(not manager._is_compatible(wavy_rule, moving_stack_rules))
	assert(not manager._is_compatible(wavy_rule, shaking_rules))
	for movement_rule in [moving_stack_rules[0], shaking_rule, wavy_rule]:
		var movement_rules: Array[SpecialRuleData] = [movement_rule]
		assert(manager._is_compatible(shell_rule, movement_rules))
		assert(not manager._is_compatible(musical_rule, movement_rules))
	assert(manager._is_compatible(musical_rule, shell_game_rules))
	assert(DifficultySettings.MERRY_GO_STACK_SPEED > 0.0)
	assert(
		DifficultySettings.MERRY_GO_STACK_MINIMUM_RADIUS
		> DifficultySettings.MINIMUM_PILE_DISTANCE
	)
	assert(DifficultySettings.SHAKING_PILES_AMPLITUDE_X > 0.0)
	assert(DifficultySettings.SHAKING_PILES_AMPLITUDE_Y > 0.0)
	assert(DifficultySettings.SHAKING_PILES_FREQUENCY_X > 0.0)
	assert(DifficultySettings.SHAKING_PILES_FREQUENCY_Y > 0.0)
	assert(DifficultySettings.WAVY_BABY_AMPLITUDE == 12.0)

	manager._previous_drawn_rule_ids = [&"shell_game"]
	for iteration in 20:
		var non_repeating_selection := manager.select_special_rules(10, 1)
		assert(non_repeating_selection.size() == 1)
		assert(non_repeating_selection[0].id != &"shell_game")
		manager._previous_drawn_rule_ids = [&"shell_game"]
	manager._previous_drawn_rule_ids.clear()

	for round_number in [10, 18, 28, 40, 50]:
		for iteration in 40:
			var selected := manager.select_special_rules(
				round_number,
				manager.get_special_rule_capacity(round_number)
			)
			var ids: Array[StringName] = []
			for rule in selected:
				assert(not ids.has(rule.id))
				ids.append(rule.id)
			assert(not (ids.has(&"lights_out") and ids.has(&"shell_game")))
			assert(not (ids.has(&"lights_out") and ids.has(&"merry_go_stack")))
			if manager.get_special_rule_capacity(round_number) >= 5:
				assert(selected.size() == 5)

	var announcement := AnnouncementScript.new() as SpecialRuleAnnouncement
	var named_combinations := {
		"BLIND DATE": [&"peek_a_card", &"lights_out"],
		"ONE STEP FORWARD...": [&"stack_attack", &"pile_up"],
		"THE EMPIRE RISES": [&"pile_up", &"roman_holiday"],
		"ET TU, STACK?": [&"roman_holiday", &"shell_game"],
		"CARDIO TRAINING": [&"peek_a_card", &"free_range_cards"],
		"FEAR OF THE STACK": [&"stack_attack", &"lights_out"],
		"LOOK, DON'T CARRY": [&"blind_delivery", &"peek_a_card"],
	}
	for expected_title: String in named_combinations:
		var combination_rules: Array[SpecialRuleData] = []
		for rule_id: StringName in named_combinations[expected_title]:
			for rule in manager._rules:
				if rule.id == rule_id:
					combination_rules.append(rule)
					break
		assert(announcement._combination_title(combination_rules) == expected_title)
	var larger_combination: Array[SpecialRuleData] = [
		find_rule.call(&"lights_out"),
		find_rule.call(&"peek_a_card"),
		find_rule.call(&"roman_holiday"),
	]
	assert(announcement._combination_title(larger_combination) == "BLIND DATE")

	announcement.free()
	manager.free()
	print("Special Rules tests passed.")
	quit()

extends SceneTree

const ManagerScript := preload("res://resources/scripts/special_rules/SpecialRuleManager.gd")


func _init() -> void:
	var manager := ManagerScript.new() as SpecialRuleManager
	assert(manager.get_special_rule_capacity(1) == 0)
	assert(manager.get_special_rule_capacity(3) == 0)
	assert(manager.get_special_rule_capacity(4) == 1)
	assert(manager.get_special_rule_capacity(7) == 1)
	assert(manager.get_special_rule_capacity(8) == 2)
	assert(manager.get_special_rule_capacity(11) == 2)
	assert(manager.get_special_rule_capacity(12) == 3)
	assert(manager.get_special_rule_capacity(16) == 4)
	assert(manager.get_special_rule_capacity(20) == 5)
	assert(manager.get_special_rule_capacity(100) == DifficultySettings.MAX_COMBINED_RULES)
	assert(manager.roll_rule_count(1) == 0)
	assert(manager.roll_rule_count(3) == 0)

	assert(manager.get_guaranteed_rule_count(1) == 0)
	assert(manager.get_guaranteed_rule_count(5) == 1)
	assert(manager.get_guaranteed_rule_count(10) == 1)
	assert(manager.get_guaranteed_rule_count(15) == 1)
	assert(manager.get_guaranteed_rule_count(20) == 1)
	assert(manager.get_guaranteed_rule_count(25) == 1)
	assert(manager.get_guaranteed_rule_count(30) == 1)

	var debug_locks: Array[StringName] = [
		&"shell_game",
		&"merry_go_stack",
		&"roman_holiday",
		&"roman_holiday",
	]
	var debug_selection := manager._select_locked_rules(debug_locks, 1)
	assert(debug_selection.size() == 2)
	assert(debug_selection[0].id == &"shell_game")
	assert(debug_selection[1].id == &"roman_holiday")

	for round_number in [10, 20, 24, 25, 35]:
		for iteration in 40:
			var selected := manager.select_special_rules(
				round_number,
				manager.get_special_rule_capacity(round_number)
			)
			var ids: Array[StringName] = []
			for rule in selected:
				assert(not ids.has(rule.id))
				ids.append(rule.id)
			assert(not (ids.has(&"shell_game") and ids.has(&"merry_go_stack")))
			assert(not (ids.has(&"free_range_cards") and ids.has(&"lights_out")))
			if round_number < DifficultySettings.HARD_COMBO_MINIMUM_ROUND:
				assert(not (ids.has(&"peek_a_card") and ids.has(&"lights_out")))

	manager.free()
	print("Special Rules tests passed.")
	quit()

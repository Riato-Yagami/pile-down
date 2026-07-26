extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var announcement := (
		load("res://resources/scenes/SpecialRuleAnnouncement.tscn").instantiate()
		as SpecialRuleAnnouncement
	)
	root.add_child(announcement)
	await process_frame
	var rules := SpecialRuleRegistry.create_all_rules().slice(0, 2)
	var protected_last_rule := await announcement.choose_rules_to_delete(
		[rules[0]],
		1,
		false
	)
	assert(protected_last_rule.is_empty())
	var first_click := create_timer(0.25)
	first_click.timeout.connect(
		func() -> void:
			announcement.rule_delete_requested.emit(1)
	)
	var second_click := create_timer(0.85)
	second_click.timeout.connect(
		func() -> void:
			announcement.rule_delete_requested.emit(0)
	)
	var removed := await announcement.choose_rules_to_delete(rules, 2, true)
	assert(removed == [1, 0])
	print("Rule Breaker bonus test passed.")
	quit()

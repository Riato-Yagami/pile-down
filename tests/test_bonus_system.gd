extends SceneTree


func _init() -> void:
	var debug_manager := BonusManager.new()
	debug_manager.begin_run()
	assert(debug_manager.level(&"lucky_hand") == 1)
	assert(is_equal_approx(debug_manager.lucky_hand_chance(), 1.0))
	debug_manager.free()

	var manager := BonusManager.new()
	manager.rng.seed = 42
	assert(manager.definitions.size() == 18)
	for definition in manager.definitions:
		assert(DifficultySettings.is_bonus_enabled(definition.id))
	var choices := manager.generate_choices(20)
	assert(choices.size() == DifficultySettings.BONUS_CHOICE_COUNT)
	assert(choices[0].id != choices[1].id)
	assert(choices[0].category != choices[1].category)
	assert(_find(manager, &"rule_breaker").max_level == 3)
	assert(_find(manager, &"bring_a_friend").max_level == 3)
	assert(_find(manager, &"pile_mover").max_level == 1)
	assert(_find(manager, &"double_down").max_level == 3)
	assert(_find(manager, &"deja_vu").max_level == 3)
	assert(_find(manager, &"bring_a_friend").rarity == BonusData.Rarity.RARE)
	var rule_breaker := _find(manager, &"rule_breaker")
	manager._add_or_upgrade(rule_breaker)
	assert(manager.rule_breaker_deletion_count() == 1)
	assert(not manager.rule_breaker_can_delete_last_rule())
	manager._add_or_upgrade(rule_breaker)
	assert(manager.rule_breaker_deletion_count() == 1)
	assert(manager.rule_breaker_can_delete_last_rule())
	manager._add_or_upgrade(rule_breaker)
	assert(manager.rule_breaker_deletion_count() == 2)

	var wild := _find(manager, &"wild_card")
	manager._add_or_upgrade(wild)
	assert(manager.level(&"wild_card") == 1)
	assert(manager.consume_forced_joker())
	assert(not manager.consume_forced_joker())
	manager._add_or_upgrade(wild)
	assert(manager.level(&"wild_card") == 2)
	assert(is_equal_approx(manager.joker_chance(), 0.1))

	var warmup := _find(manager, &"slow_start")
	manager._add_or_upgrade(warmup)
	manager._add_or_upgrade(warmup)
	manager.begin_round()
	assert(is_equal_approx(manager.next_hand_time(5.0), 7.0))
	assert(is_equal_approx(manager.next_hand_time(5.0), 7.0))
	assert(is_equal_approx(manager.next_hand_time(5.0), 7.0))
	assert(is_equal_approx(manager.next_hand_time(5.0), 6.0))

	var safety := _find(manager, &"safety_net")
	manager._add_or_upgrade(safety)
	manager.begin_round()
	assert(manager.consume_safety_net())
	assert(not manager.consume_safety_net())

	print("Bonus system tests passed.")
	quit()


func _find(manager: BonusManager, id: StringName) -> BonusData:
	for data in manager.definitions:
		if data.id == id:
			return data
	assert(false)
	return null

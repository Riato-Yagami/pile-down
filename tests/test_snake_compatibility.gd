extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")
const BLOCKED: Array[StringName] = [
	&"merry_go_stack", &"shaking_piles", &"wavy_baby", &"free_range_cards",
	&"musical_stacks", &"pile_up", &"floor_is_lava",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(180).timeout.connect(func(): quit(1))
	var manager := SpecialRuleManager.new()
	var snake_rule := load("res://resources/data/special_rules/20_snake.tres") as SpecialRuleData
	var checked := 0
	for filename in DirAccess.get_files_at("res://resources/data/special_rules"):
		if not filename.ends_with(".tres"):
			continue
		var rule := load("res://resources/data/special_rules/" + filename) as SpecialRuleData
		if rule.id == &"snake":
			continue
		var snake_only: Array[SpecialRuleData] = [snake_rule]
		var other_only: Array[SpecialRuleData] = [rule]
		var compatible := not BLOCKED.has(rule.id)
		assert(manager._is_compatible(rule, snake_only) == compatible, str(rule.id))
		assert(manager._is_compatible(snake_rule, other_only) == compatible, str(rule.id))
		checked += 1
		if compatible:
			if OS.get_cmdline_user_args().is_empty() or str(rule.id) in OS.get_cmdline_user_args():
				await _check_pair(rule.id)
		else:
			print("Snake excluded: ", rule.id)
	if OS.get_cmdline_user_args().is_empty():
		await _check_pair(&"mirror_match", [&"shell_game", &"stack_attack", &"roman_holiday", &"grace_period"])
		await _check_pair(&"mirror_match", [&"sticky_fingers", &"hot_potatoes", &"blind_delivery", &"peek_a_card"])
	manager.free()
	assert(checked == 20)
	print("Snake compatibility audit passed: 20 pairs, 13 gameplay pairs, two six-rule combinations and all mirror axes.")
	quit()


func _check_pair(rule_id: StringName, extra_rules: Array[StringName] = []) -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	var rules: Array[StringName] = [&"snake", rule_id]
	rules.append_array(extra_rules)
	game.start_game(false, null, false, "SNAKE-COMPAT-" + str(rule_id), {}, rules,
		{"pile_count": 4, "hand_size": 4, "start_value": 5, "turn_time": 100.0})
	while game.input_locked or game.hand_manager.current_cards.is_empty():
		await process_frame
	var snake := game.snake_rule_controller
	snake.set_process(false)
	game.timer_manager.stop_countdown()
	game.hand_manager.finish_all_card_entrances()
	assert(snake.active and snake.card_cells.size() == 4)
	assert(game.special_rule_manager.active_rules.size() == rules.size())
	if rule_id == &"sudden_death":
		assert(game.maximum_mistakes == 1)
	if rule_id == &"grace_period":
		assert(game.round_modifiers.grace_period_duration > 0.0)
	if game.round_modifiers.regeneration_enabled:
		assert(game.piles.any(func(p: MemoryPile): return p.regeneration_enabled))
		for pile in game.piles:
			pile.disable_regeneration()
	if rule_id == &"mirror_match":
		for axes in [Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			game.scale = axes
			snake._place_segments()
			snake.place_hand()
			game.hand_manager.finish_all_card_entrances()
			await _check_geometry_and_meal(game)
	else:
		await _check_geometry_and_meal(game)
	# The normal success path must keep the other rule's effects and the grid.
	game.hand_manager.finish_all_card_entrances()
	var card := game.hand_manager.current_cards[0]
	var pile := snake.segments[0]
	card.card_value = pile.expected_value()
	card.dragging = true
	game.selected_card = card
	var previous_value := pile.current_value
	game.timer_manager.running = true
	await game._on_card_drag_released(card, (pile.get_global_transform() * (pile.size * 0.5)))
	while game.input_locked:
		await process_frame
	assert(pile.current_value == previous_value - 1)
	game.timer_manager.stop_countdown()
	for index in snake.segments.size():
		assert(snake._pile_grid_position(snake.segments[index]).is_equal_approx(snake._global_position(snake.cells[index])), "%s segment %d: %s expected %s" % [rule_id, index, snake.segments[index].global_position, snake._global_position(snake.cells[index])])
	await game.cleanup_special_rule_state()
	await game.special_rule_manager.end_round(game.piles, false)
	assert(not snake.active and snake._meal_visuals.is_empty())
	assert(game.scale.is_equal_approx(Vector2.ONE))
	game.queue_free()
	await process_frame
	print("Snake gameplay verified: ", rules)


func _check_geometry_and_meal(game: GameManager) -> void:
	var snake := game.snake_rule_controller
	assert(snake._cell_overlaps_snake(snake.cells[0]), "Body rectangle mismatch: scale=%s pile=%s grid=%s" % [game.scale, snake.segments[0].get_global_rect(), game.get_global_transform() * Rect2(snake._position(snake.cells[0]), Vector2(34, 37))])
	snake.meal_pause_remaining = 0.0
	snake.step()
	snake._advance_slide(snake._slide_duration * 0.5)
	for cell in snake._free_cells():
		var rect := (game.get_global_transform() * Rect2(snake._position(cell), Vector2(34, 37))).abs()
		for pile in snake.segments:
			assert(not rect.intersects(snake._tile_rect(pile)), "Respawn overlaps moving body")
	snake._advance_slide(1.0)
	# Food released over a segment must work through reflected hitboxes too.
	game.hand_manager.finish_all_card_entrances()
	for card in game.hand_manager.current_cards:
		card.card_value = 4
	var card := game.hand_manager.current_cards[0]
	var tail := snake.segments.back() as MemoryPile
	tail.current_value = 2
	snake.meal_heal_chance = 1.0
	card.global_position = snake.segments[0].global_position
	card.dragging = true
	game.selected_card = card
	assert(snake.try_release_card(card, null), "Loose food must land on a mirrored body")
	assert(snake._meal_visuals.size() == 1)
	assert(tail.current_value == 2)
	await create_timer(0.8).timeout
	assert(tail.current_value == 3)
	assert(snake.card_cells.has(card))
	assert(not snake.cells.has(snake.card_cells[card]))
	assert(card.hand_return_position().is_equal_approx(card.global_position))
	assert(card.visual_root.scale.is_equal_approx(Vector2.ONE))

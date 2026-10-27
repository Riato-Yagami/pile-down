extends "res://tests/test_seed_replay.gd"

var samples: Array[Dictionary] = []


func _run() -> void:
	create_timer(240).timeout.connect(func(): quit(1))
	var cases := {
		"baseline": [&"roman_holiday"],
		"shell": [&"shell_game"],
		"musical": [&"musical_stacks"],
		"orbit": [&"merry_go_stack"],
		"shake": [&"shaking_piles"],
		"wave": [&"wavy_baby"],
		"snake": [&"snake"],
		"snake_shell": [&"snake", &"shell_game"],
		"mover": [&"roman_holiday"],
		"mover_orbit": [&"merry_go_stack"],
		"mover_shake": [&"shaking_piles"],
		"mover_wave": [&"wavy_baby"],
		"mirror_orbit": [&"merry_go_stack", &"mirror_match"],
	}
	for count in [3, 13, 25]:
		for label: String in cases:
			if count != 13 and not label in ["baseline", "orbit", "snake", "mover", "wave"]:
				continue
			var rules: Array[StringName] = []
			rules.assign(cases[label])
			await _audit(label, rules, count)
	var output := OS.get_environment("PILE_DOWN_SHARE_AUDIT_OUTPUT")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		assert(file != null)
		file.store_string(JSON.stringify(samples, "\t"))
	print("Movement share audit passed: 23 scenarios, ", samples.size(), " snapshots.")
	quit()


func _audit(label: String, rules: Array[StringName], count: int) -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	var bonuses := {&"pile_mover": 1} if label.begins_with("mover") else {&"adaptation": 3} if label.begins_with("adaptation") else {}
	game.start_game(false, null, false, "SHARE-MOVEMENT-" + label, bonuses, rules,
		{"pile_count": count, "hand_size": 1, "start_value": 9, "turn_time": 100.0})
	await _wait_for_hand(game)
	if label.begins_with("adaptation"):
		assert(game.bonus_manager.level(&"adaptation") == 3)
	game.timer_manager.stop_countdown()
	game.snake_rule_controller.set_process(false)
	var pattern := game.special_rule_manager.moving_pile_pattern
	pattern.set_process(false)
	for index in count:
		game.piles[index].current_value = index % 9 + 1
	_record(game, label, "initial")
	if label.begins_with("mover"):
		assert(game.bonus_manager.has_bonus(&"pile_mover"))
		for index in mini(count, 3):
			var pile := game.piles[index]
			game._on_pile_drag_requested(pile, pile.get_global_transform() * (pile.size * 0.5))
			assert(game.moving_pile == pile)
			pile.position += Vector2(28 - index * 20, 32 + index * 9)
			game._finish_pile_move()
		_record(game, label, "manual_release")
	for phase in 3:
		if pattern.active:
			pattern._process(0.65)
		if game.round_modifiers.snake_enabled:
			var snake := game.snake_rule_controller
			snake.step()
			snake._advance_slide(snake._slide_duration * 0.5)
			_record(game, label, "slide_%d" % phase)
			snake._advance_slide(1.0)
		if game.round_modifiers.swap_piles_after_play:
			var done := [false]
			_swap(game, done)
			await create_timer(0.25).timeout
			_record(game, label, "swap_%d" % phase)
			while not done[0]:
				await process_frame
		if game.round_modifiers.musical_stacks_enabled:
			await game.pile_manager.rotate_active_piles(1, 0.02)
		_record(game, label, "phase_%d" % phase)
	var current_grid := ResultShare.capture_tiles(game.piles)
	game.piles[0].scale.x = 0.02
	assert(ResultShare.capture_tiles(game.piles) == current_grid, "A value flip must not change the share layout")
	game.piles[0].scale = Vector2.ONE
	game.scale.x *= -1
	_record(game, label, "mirrored")
	game.scale.x *= -1
	for index in range(0, count, 4):
		game.piles[index].completed = true
		game.piles[index].hide()
	_record(game, label, "completed")
	await game.cleanup_special_rule_state(false)
	await game.special_rule_manager.end_round(game.piles, false)
	game.queue_free()
	await process_frame
	print("Share movement checked: ", label, " / ", count)


func _swap(game: GameManager, done: Array) -> void:
	await game.special_rule_manager.after_card_played(game.piles, DifficultySettings.THREE_PILE_SHELL_GAME_ROUND)
	done[0] = true


func _record(game: GameManager, label: String, phase: String) -> void:
	var grid := ResultShare.capture_tiles(game.piles)
	var points: Array[Dictionary] = []
	var expected := 0
	for pile in game.piles:
		var center := ResultShare._layout_center(pile)
		points.append({"x": center.x, "y": center.y, "value": pile.current_value, "completed": pile.completed})
		if not pile.completed:
			expected += 1
	var found := 0
	for value in range(1, 10):
		found += grid.count(ResultShare._number_tile(value))
	assert(found == expected, "%s / %s lost a tile" % [label, phase])
	assert(grid.split("\n").size() <= ResultShare.MAX_BOARD_ROWS)
	assert(not grid.contains("⬜") and not grid.contains("✅"))
	samples.append({"case": label, "count": game.piles.size(), "phase": phase, "points": points, "grid": grid})

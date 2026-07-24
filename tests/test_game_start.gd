extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	assert(game.splash_debug_mode.visible == DebugSettings.is_enabled())
	var play_event := InputEventKey.new()
	play_event.keycode = KEY_SPACE
	play_event.pressed = true
	assert(game._handle_global_shortcut(play_event))
	var mute_event := InputEventKey.new()
	mute_event.keycode = KEY_M
	mute_event.pressed = true
	var initial_mute_state := game.soft_audio.is_muted()
	assert(game._handle_global_shortcut(mute_event))
	assert(game.soft_audio.is_muted() != initial_mute_state)
	assert(game._handle_global_shortcut(mute_event))
	assert(game.soft_audio.is_muted() == initial_mute_state)
	await create_timer(7.0).timeout
	var time_event := InputEventKey.new()
	time_event.keycode = KEY_T
	time_event.pressed = true
	assert(game._handle_global_shortcut(time_event))
	assert(game.run_time_label.visible)
	assert(game.run_time_label.text.contains(" s "))
	assert(game._handle_global_shortcut(time_event))
	assert(not game.run_time_label.visible)
	var configured_start := DebugSettings.get_start_round(DifficultySettings.TOTAL_ROUNDS)
	assert(game.piles.size() == game.pile_count)
	assert(game.pile_count >= DifficultySettings.START_PILES)
	assert(not game.hand_manager.current_cards.is_empty())
	assert(
		game.round_number
		== DifficultySettings.TOTAL_ROUNDS - configured_start + 1
	)
	assert(game.pile_count >= DifficultySettings.START_PILES)
	assert(game.hand_size >= DifficultySettings.START_HAND_SIZE)
	assert(game.start_value >= DifficultySettings.START_CARD_VALUE)
	assert(game.turn_time <= DifficultySettings.START_TURN_TIME)
	assert(game.turn_time >= DifficultySettings.MIN_TURN_TIME)
	var expected_reliefs := 0
	for progression_round in range(2, configured_start + 1):
		if game._is_special_tier_relief_round(progression_round):
			expected_reliefs += 1
	assert(game.tier_reliefs_applied == expected_reliefs)
	for relief_round in [10, 18, 28, 40, 54, 70, 88]:
		assert(game._is_special_tier_relief_round(relief_round))
	assert(not game._is_special_tier_relief_round(41))
	assert(
		game.special_rule_manager.get_special_rule_capacity(88)
		== DifficultySettings.MAX_COMBINED_RULES
	)
	game.pile_count = 10
	game.hand_size = 4
	game.start_value = 9
	game.turn_time = 2.0
	game.tier_reliefs_applied = 0
	assert(game._advance_difficulty(10) == "TIER RELIEF")
	var relieved_stats := 0
	relieved_stats += int(game.pile_count == 9)
	relieved_stats += int(game.hand_size == 3)
	relieved_stats += int(game.start_value == 8)
	relieved_stats += int(is_equal_approx(game.turn_time, 3.0))
	assert(relieved_stats == 1)
	game.pile_count = DifficultySettings.MAX_PILES
	game.hand_size = DifficultySettings.MAX_HAND_SIZE
	game.start_value = DifficultySettings.MAX_CARD_VALUE
	game.turn_time = DifficultySettings.MIN_TURN_TIME
	assert(game._increase_difficulty(0).is_empty())
	print("Game start integration test passed.")
	game.queue_free()
	await process_frame
	quit()

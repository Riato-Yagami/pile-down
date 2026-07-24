extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
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
		if (
			game.special_rule_manager.get_special_rule_capacity(progression_round)
			> game.special_rule_manager.get_special_rule_capacity(progression_round - 1)
		):
			expected_reliefs += 1
	assert(game.tier_reliefs_applied == expected_reliefs)
	print("Game start integration test passed.")
	game.queue_free()
	quit()

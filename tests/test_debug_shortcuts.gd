extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_until_unlocked(game)

	assert(game.debug_help.visible)
	assert(game.debug_help.text.contains("[S] NEXT MUSIC SECTION"))
	assert(game.debug_help.text.contains("[L] LOSE ONE LIFE"))
	assert(game.debug_help.text.contains("[K] DIE NOW"))
	assert(game.debug_help.text.contains("[U] TOGGLE UNLOCK EVERYTHING"))
	var section_event := InputEventKey.new()
	section_event.keycode = KEY_S
	section_event.pressed = true
	var initial_section := game.music_manager.current_section
	assert(game._handle_debug_shortcut(section_event))
	assert(game.music_manager.current_section == initial_section)
	assert(game.music_manager.section_change_requested)

	var initial_god_mode := DebugSettings.is_god_mode_enabled()
	var god_event := InputEventKey.new()
	god_event.keycode = KEY_G
	god_event.pressed = true
	assert(game._handle_debug_shortcut(god_event))
	assert(DebugSettings.is_god_mode_enabled() != initial_god_mode)
	assert(game.debug_help.text.contains("GOD MODE: ON"))

	var reset_event := InputEventKey.new()
	reset_event.keycode = KEY_R
	reset_event.pressed = true
	assert(game._handle_debug_shortcut(reset_event))
	await _wait_until_unlocked(game)
	assert(game.round_number == DifficultySettings.TOTAL_ROUNDS)

	game.best_rounds_left = 12
	game.best_score_time_ms = 1234
	game.unlocked_checkpoints.assign([1, 2])
	game.checkpoint_snapshots = {1: {"start_round": 10}}
	game.discovered_bonuses.assign([&"wild_card"])
	game.achievement_manager.unlocked.assign([&"max_piles"])
	var high_score_event := InputEventKey.new()
	high_score_event.keycode = KEY_H
	high_score_event.pressed = true
	assert(game._handle_debug_shortcut(high_score_event))
	assert(game.best_rounds_left == -1)
	assert(game.best_score_time_ms == -1)
	assert(game.unlocked_checkpoints.is_empty())
	assert(game.checkpoint_snapshots.is_empty())
	assert(game.discovered_bonuses.is_empty())
	assert(game.achievement_manager.unlocked.is_empty())
	assert(game.splash_high_score.text == "HIGH SCORE\n--")

	print("Debug shortcut integration test passed.")
	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

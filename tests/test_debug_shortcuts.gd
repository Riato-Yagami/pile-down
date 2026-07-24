extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_until_unlocked(game)

	var initial_round := game.round_number
	var skip_event := InputEventKey.new()
	skip_event.keycode = KEY_S
	skip_event.pressed = true
	assert(game._handle_debug_shortcut(skip_event))
	await _wait_until_unlocked(game)
	assert(game.round_number == initial_round - 1)

	var reset_event := InputEventKey.new()
	reset_event.keycode = KEY_R
	reset_event.pressed = true
	assert(game._handle_debug_shortcut(reset_event))
	await _wait_until_unlocked(game)
	assert(game.round_number == initial_round)

	game.best_rounds_left = 12
	game.best_score_time_ms = 1234
	var high_score_event := InputEventKey.new()
	high_score_event.keycode = KEY_H
	high_score_event.pressed = true
	assert(game._handle_debug_shortcut(high_score_event))
	assert(game.best_rounds_left == -1)
	assert(game.best_score_time_ms == -1)
	assert(game.splash_high_score.text == "HIGH SCORE\n--")

	print("Debug shortcut integration test passed.")
	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

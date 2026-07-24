extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_until_unlocked(game)

	game.best_rounds_left = game.round_number + 1
	game.best_score_time_ms = 1000
	assert(game._update_high_score(game.round_number, 2000) == "ROUND")
	assert(game._update_high_score(game.round_number, 1500) == "TIME")
	assert(game._update_high_score(game.round_number, 1600).is_empty())

	game.best_rounds_left = game.round_number
	game.best_score_time_ms = 2000
	game.round_reached_time_ms = 1500
	await game._finish_game(false)
	assert(game.best_score_time_ms == 1500)
	assert(game.overlay_title.text == "TIME RECORD")
	assert(game.overlay_details.text.contains("time: 01:500"))

	print("High score integration test passed.")
	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

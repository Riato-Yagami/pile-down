extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	assert(DifficultySettings.round_start_lives(1, 3, false) == 2)
	assert(DifficultySettings.round_start_lives(3, 3, false) == 3)
	assert(DifficultySettings.round_start_lives(2, 5, false) == 3)
	assert(DifficultySettings.round_start_lives(3, 1, false) == 1)
	assert(DifficultySettings.round_start_lives(0, 5, true) == 5)
	assert(DifficultySettings.round_start_lives(1, 5, false, -1) == 5)
	assert(DifficultySettings.round_start_lives(1, 3, false, 0) == 1)
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	await _wait_for_round(game)
	assert(game.mistakes_left == game.maximum_mistakes)
	game.run_completed_rounds = 1
	game.mistakes_left = 1
	game.start_round()
	await _wait_for_round(game)
	assert(game.mistakes_left == 2, "A cleared round must restore only one life")
	game.run_completed_rounds = 2
	game.start_round()
	await _wait_for_round(game)
	assert(game.mistakes_left == 3)
	game.mistakes_left = 0
	game.start_game()
	await _wait_for_round(game)
	assert(game.mistakes_left == game.maximum_mistakes, "Restart must restore full health")
	var dots := game.mistakes_dots
	dots.set_remaining(1)
	dots.set_remaining(2)
	dots.play_recovery(1)
	assert(dots.life_points[1].scale.x < 1.0)
	assert(dots.life_points[0].scale == Vector2.ONE)
	await create_timer(0.5).timeout
	assert(dots.life_points[1].scale.is_equal_approx(Vector2.ONE))
	assert(dots.life_points[1].modulate == Color.WHITE)
	dots.set_maximum(6)
	dots.set_reinforced_count(3)
	dots.set_remaining(4)
	dots.play_recovery(3)
	assert(dots.life_points[2].scale.x < 1.0)
	# A state change interrupts recovery without leaving a stretched/tinted dot.
	dots.set_remaining(3)
	assert(dots.life_points[2].scale == Vector2.ONE)
	assert(dots.life_points[2].modulate == Color.WHITE)
	game.queue_free()
	await process_frame
	print("Round life regeneration tests passed.")
	quit()


func _wait_for_round(game: GameManager) -> void:
	while game.input_locked:
		await process_frame
	game.timer_manager.stop_countdown()

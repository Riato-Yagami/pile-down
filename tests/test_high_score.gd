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
	# Death records include time spent in the current, unfinished round.
	game.round_reached_time_ms = 750
	game.run_pause_started_msec = Time.get_ticks_msec()
	game.game_started_msec = game.run_pause_started_msec - 1500
	game.run_paused_msec = 0
	await game._finish_game(false)
	assert(game.best_score_time_ms == 1500)
	assert(game.overlay_high_score.visible)
	assert(game.overlay_high_score.text.contains("HIGHSCORE"))
	var colored_time := "[color=#%s]%s[/color]" % [
		GameColors.ACCENT.to_html(false),
		TranslationServer.translate("in %s") % "1 s 500 ms",
	]
	assert(game.overlay_details.text.contains(colored_time))

	await create_timer(0.4).timeout
	print("High score integration test passed.")
	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

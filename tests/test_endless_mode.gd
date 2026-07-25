extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)

	game._unlock_endless_mode()
	assert(game.endless_unlocked)
	assert(game.endless_button.visible)

	game.endless_best_round = 7
	game.endless_best_time_ms = 1234
	game._show_endless_high_score()
	assert(game.splash_high_score.text.contains("ENDLESS HIGHSCORE"))
	assert(game.splash_high_score.text.contains("round 7"))
	assert(game.splash_high_score_time.text == "in 1 s 234 ms")
	game._refresh_high_score()
	assert(not game.splash_high_score.text.contains("ENDLESS"))

	assert(game._update_endless_high_score(8, 2000) == "ROUND")
	assert(game._update_endless_high_score(8, 1500) == "TIME")
	assert(game._update_endless_high_score(7, 1000).is_empty())

	game.start_game(true)
	assert(game.game_mode == GameManager.GameMode.ENDLESS)
	assert(game.round_number == 1)
	assert(game._progression_round() == 1)
	game.round_number = 51
	assert(game._progression_round() == 51)

	print("Endless mode integration test passed.")
	game.queue_free()
	await process_frame
	quit()

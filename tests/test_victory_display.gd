extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.game_mode = GameManager.GameMode.CHECKPOINT
	game.checkpoint_uses_endless_progression = false
	game.round_number = 0
	game._debug_action_in_progress = true
	game._debug_round_wins_queued = 3
	game._shared_clock_timeout_pending = true
	game._conveyor_active = true
	game.timer_manager.start_countdown(10.0)
	var gameplay_generation := game._gameplay_generation
	var hand_generation := game._hand_cycle_generation
	await game._finish_game(true)
	assert(game.overlay_title.text.contains("YOU WIN"))
	assert(not game.overlay_title.text.contains("0 ROUNDS"))
	assert(game.overlay.visible)
	assert(game.input_locked)
	assert(not game.timer_manager.running)
	assert(game._debug_round_wins_queued == 0)
	assert(not game._shared_clock_timeout_pending)
	assert(not game._conveyor_active)
	assert(game._gameplay_generation > gameplay_generation)
	assert(game._hand_cycle_generation > hand_generation)
	game.checkpoint_uses_endless_progression = true
	assert(not game._is_finite_mode_victory(true))
	game._debug_round_wins_queued = 2
	game._shared_clock_timeout_pending = true
	game._conveyor_active = true
	game.timer_manager.start_countdown(5.0)
	await game._finish_game(false)
	assert(game.overlay.visible)
	assert(game.input_locked)
	assert(not game.timer_manager.running)
	assert(game._debug_round_wins_queued == 0)
	assert(not game._shared_clock_timeout_pending)
	assert(not game._conveyor_active)
	print("Victory display test passed.")
	game.queue_free()
	quit()

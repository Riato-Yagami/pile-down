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
	assert(game.end_seed_display.visible)
	assert(game.end_seed_display.value_label.text.begins_with(game.run_seed_label.left(5)))
	assert(game.end_seed_display.copy_button.texture_normal != null)
	await process_frame
	assert(
		game.overlay_panel.get_global_rect().encloses(
			game.end_seed_display.get_global_rect()
		)
	)
	game.end_seed_display.set_seed(
		"0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz"
	)
	game.end_seed_display._set_highlight(true)
	await create_timer(game.end_seed_display.resize_animation_duration + 0.05).timeout
	assert(game.end_seed_display.value_label.text.contains("\n"))
	assert(
		game.overlay_panel.get_global_rect().encloses(
			game.end_seed_display.get_global_rect()
		)
	)
	assert(game.input_locked)
	assert(not game.timer_manager.running)
	assert(game._debug_round_wins_queued == 0)
	assert(not game._shared_clock_timeout_pending)
	assert(not game._conveyor_active)
	assert(game._gameplay_generation > gameplay_generation)
	assert(game._hand_cycle_generation > hand_generation)
	game.overlay_high_score.visible = true
	game.overlay_unlocks.visible = true
	game.overlay_unlocks.text = "[center]+ FIRST\n+ SECOND[/center]"
	game._position_overlay_result_extras()
	await process_frame
	game._position_overlay_result_extras()
	await process_frame
	var result_stack := game.get_node(
		"Screens/Overlay/OverlayCenter/ResultStack"
	) as VBoxContainer
	var high_score_gap := game.overlay_panel.global_position.y - (
		game.overlay_high_score.global_position.y + game.overlay_high_score.size.y
	)
	var progression_gap := game.overlay_unlocks.global_position.y - (
		game.overlay_panel.global_position.y + game.overlay_panel.size.y
	)
	assert(is_equal_approx(high_score_gap, 6.0))
	assert(is_equal_approx(progression_gap, 6.0))
	assert(result_stack.size.y < game.size.y)
	assert(game.overlay_high_score.global_position.y > 0.0)
	assert(game.overlay_unlocks.get_global_rect().end.y < game.size.y)
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

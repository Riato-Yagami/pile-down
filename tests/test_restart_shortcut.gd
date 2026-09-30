extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	var key := InputEventKey.new()
	key.keycode = KEY_R
	key.pressed = true
	assert(not game._handle_global_shortcut(key), "R must not start a run from the title")
	game.start_game()
	while game.input_locked:
		await process_frame
	game.timer_manager.stop_countdown()
	key.echo = true
	assert(not game._handle_global_shortcut(key))
	key.echo = false
	# Exercise the global path, which has no dependency on debug settings.
	assert(game._handle_global_shortcut(key))
	assert(game._screen_transition_active, "R must use the Replay transition")
	while game._screen_transition_active:
		await process_frame
	assert(not game._debug_action_in_progress)
	await create_timer(game.pile_value_hold_duration + 0.3).timeout
	for pile in game.piles:
		assert(pile.face_up, "Replay must preserve extra reading time for initial values")
	game.queue_free()
	await process_frame
	print("Restart shortcut tests passed.")
	quit()

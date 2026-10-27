extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(25).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	game.start_game(false, null, false, "SNAKE-ANIMATION", {}, [&"snake"], {"pile_count": 4, "hand_size": 1, "start_value": 5, "turn_time": 100.0})
	while game.input_locked or game.hand_manager.current_cards.is_empty():
		await process_frame
	var snake := game.snake_rule_controller
	snake.set_process(false)
	game.timer_manager.stop_countdown()
	var card := game.hand_manager.current_cards[0]
	var position := card.global_position
	snake._respawn(card)
	position = card.global_position
	assert(card.modulate.a == 0.0)
	assert(card.visual_root.scale.x < 0.1)
	assert(card._entrance_unlock_pending)
	var head_center := snake.segments[0].get_global_rect().get_center()
	var distance := position.distance_to(head_center)
	for cell in snake._free_cells():
		assert(distance + 0.01 >= snake._global_position(cell).distance_to(head_center) * 0.7)
	await create_timer(0.14).timeout
	assert(card.visual_root.scale.x > 0.05 and card.visual_root.scale.x < 1.0)
	assert(card.modulate.a > 0.0 and card.modulate.a < 1.0)
	assert(card.global_position.is_equal_approx(position))
	card.finish_entrance_immediately()
	assert(card.visual_root.scale.is_equal_approx(Vector2.ONE))
	assert(card.modulate.a == 1.0)
	var exit_finished := [false]
	_discard(game, exit_finished)
	await create_timer(0.12).timeout
	assert(card.global_position.is_equal_approx(position))
	assert(card.visual_root.scale.x < 1.0)
	assert(card.modulate.a < 1.0)
	while not exit_finished[0]:
		await process_frame
	await process_frame
	assert(not is_instance_valid(card))
	game.queue_free()
	await process_frame
	print("Snake tile lifecycle tests passed.")
	quit()


func _discard(game: GameManager, finished: Array) -> void:
	await game.hand_manager.discard_hand(game.drag_layer, game.drag_layer, false, false)
	finished[0] = true

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
	var head := snake.segments[0]
	var tail := snake.segments.back() as MemoryPile
	var card := game.hand_manager.current_cards[0]
	card.global_position = head.global_position + Vector2(20, 0)
	snake._animate_meal(card)
	var carrier := snake._meal_visuals[0]
	var visual := carrier.get_child(0) as Control
	var start_center := carrier.global_position
	snake._update_absorption(0.5, carrier, start_center, head)
	assert(carrier.scale.is_equal_approx(Vector2.ONE * 0.75))
	assert((visual.get_global_transform() * (visual.size * 0.5)).is_equal_approx(carrier.global_position), "Shrink must preserve the visual center")
	head.position += Vector2(5, 0)
	snake._update_absorption(1.0, carrier, start_center, head)
	assert(carrier.scale.is_equal_approx(Vector2.ONE * 0.5))
	assert(carrier.global_position.is_equal_approx(head.get_global_transform() * (head.size * 0.5)))
	var head_rect := head.get_global_rect()
	await create_timer(0.16).timeout
	assert(head.visual_root.scale.is_equal_approx(Vector2.ONE), "Digestion starts after absorption")
	await create_timer(0.19).timeout
	assert(head.visual_root.scale.x > 1.0)
	assert(tail.visual_root.scale.is_equal_approx(Vector2.ONE))
	assert(head.get_global_rect() == head_rect, "The pulse must not enlarge the pile hitbox")
	await create_timer(0.27).timeout
	assert(head.visual_root.scale.is_equal_approx(Vector2.ONE))
	assert(tail.visual_root.scale.x > 1.0)
	snake.stop()
	assert(tail.visual_root.scale.is_equal_approx(Vector2.ONE))
	game.queue_free()
	await process_frame
	print("Snake meal animation tests passed: centered shrink, moving head, sequential visual pulse and cleanup.")
	quit()

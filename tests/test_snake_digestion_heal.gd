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
	var target := snake.segments[1]
	var tail := snake.segments.back() as MemoryPile
	for pile in snake.segments:
		pile.current_value = pile.start_value
	target.current_value = 2
	var card := game.hand_manager.current_cards[0]
	card.card_value = 4
	var heals := [0]
	target.regenerated.connect(func(_pile, _delta): heals[0] += 1)
	snake.meal_heal_chance = 1.0
	snake._eat(card)
	assert(target.current_value == 2, "No immediate heal")
	await create_timer(0.32).timeout
	assert(head.visual_root.scale.x > 1.0)
	assert(target.current_value == 2, "The wave has not reached the target peak")
	await create_timer(0.18).timeout
	assert(target.current_value == 3 and heals[0] == 1)
	assert(target.visual_root.scale.x > 1.0, "Heal coincides with target swelling")
	assert(tail.visual_root.scale.is_equal_approx(Vector2.ONE), "Wave stops at the healed segment")
	await create_timer(0.25).timeout
	assert(tail.visual_root.scale.is_equal_approx(Vector2.ONE))
	assert(heals[0] == 1)
	# Cancelling the rule cancels a pending heal together with its pulse.
	snake._eat(card)
	snake.stop()
	await create_timer(0.8).timeout
	assert(target.current_value == 3 and heals[0] == 1)
	game.queue_free()
	await process_frame
	print("Snake digestion heal tests passed: delayed heal, target pulse, wave cutoff and cancellation.")
	quit()

extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(20.0).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	while game.input_locked:
		await process_frame
	game.timer_manager.stop_countdown()
	var overlay := game.flashlight_overlay
	overlay.open_out(false)
	await process_frame
	overlay.visible = true
	game.round_modifiers.flashlight_enabled = true
	game.round_modifiers.wandering_hand_cards = false
	game._generate_next_hand(game._hand_cycle_generation, true, false, false)
	await create_timer(0.45).timeout
	assert(overlay.get_child_count() == game.hand_manager.current_cards.size(),
		"Every card in the initial hand must trigger exactly one afterglow")
	var card := game.hand_manager.current_cards[0]
	var glow := overlay.get_child(0)
	assert(glow._sources[0] == card.face_sprite)
	assert(glow._copies.size() == 3)
	card.value_label.hide()
	glow._process(0.0)
	assert(not glow._copies[2].visible, "Hidden values must not glow")
	card.position += Vector2(12, 8)
	glow._process(0.0)
	assert(glow._frames[0].get_global_transform_with_canvas().is_equal_approx(
		card.face_sprite.get_global_transform_with_canvas()
	))
	await create_timer(1.5).timeout
	assert(not is_instance_valid(glow), "Afterglow must expire")
	game._generate_next_hand(game._hand_cycle_generation, true, true, false)
	await create_timer(0.6).timeout
	assert(overlay.get_child_count() == game.hand_manager.current_cards.size(),
		"Sliding replacement cards must still trigger exactly one afterglow")
	overlay.illuminate_appearance(game.piles[0], 0.1)
	overlay.open_out(false)
	await create_timer(0.2).timeout
	assert(overlay.get_child_count() == 0, "Leaving the rule cancels delayed glows")
	game.queue_free()
	await process_frame
	print("Lights Out afterglow tests passed.")
	quit()

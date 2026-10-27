extends SceneTree

const MainScene := preload("res://resources/scenes/Main.tscn")
const Options := preload("res://resources/scripts/settings/GameOptionsController.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(100).timeout.connect(func(): quit(1))
	for mode in [&"semi_adaptive", &"menu_adaptive"]:
		for axes in [Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			await _check(mode, axes)
	print("Mirror quit transition passed: all reflection axes, two layouts, stable menu during swipe and reparenting.")
	quit()


func _check(mode: StringName, axes: Vector2) -> void:
	root.size = Vector2i(1000, 640)
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await create_timer(0.8).timeout
	var game := main.get_node("GameCenter/Game") as GameManager
	game._screen_size_mode = mode
	Options.apply_resolution(game)
	for frame in 6:
		await process_frame
	var buttons: Array[Control] = [game.splash_button, game.progression_button, game.options_button]
	var resting: Array[Vector2] = []
	for button in buttons:
		resting.append(button.get_global_transform_with_canvas().origin)
	game.splash.hide()
	game.special_rule_manager.suppress_next_announcement = true
	game.start_game(false, null, false, "MIRROR-QUIT", {}, [&"mirror_match"],
		{"pile_count": 2, "hand_size": 1, "start_value": 5, "turn_time": 100.0})
	while game.input_locked or game.hand_manager.current_cards.is_empty():
		await process_frame
	game.round_modifiers.mirror_horizontal = axes.x < 0
	game.round_modifiers.mirror_vertical = axes.y < 0
	game.mirror_match_controller.begin_round(game, game.round_modifiers)
	game._open_quit_popup()
	assert(game.quit_popup.visible)
	game.menu_swipe_duration = 0.35
	game._return_to_menu()
	await process_frame
	assert(game.splash.get_parent() == game.menu_transition_layer)
	var last_delta := INF
	while game._screen_transition_active:
		Options.apply_low_resolution_layout(game)
		var first_delta := 0.0
		for index in buttons.size():
			var current := buttons[index].get_global_transform_with_canvas().origin
			assert(is_equal_approx(current.x, resting[index].x), "Mirror quit shifts the menu horizontally: %s %s" % [mode, axes])
			var delta := current.y - resting[index].y
			assert(delta >= -0.1, "Menu overshoots its final vertical position")
			if index == 0:
				first_delta = delta
			else:
				assert(is_equal_approx(delta, first_delta), "Menu controls must slide together")
		assert(first_delta <= last_delta + 0.1)
		last_delta = first_delta
		await process_frame
	assert(game.scale.is_equal_approx(Vector2.ONE))
	assert(game.splash.get_parent() == game.screens)
	for index in buttons.size():
		assert(buttons[index].get_global_transform_with_canvas().origin.is_equal_approx(resting[index]), "Reparenting must not move the menu")
	assert(not game.quit_popup.visible)
	main.queue_free()
	await process_frame

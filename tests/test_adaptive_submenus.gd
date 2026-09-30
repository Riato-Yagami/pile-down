extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(35.0).timeout.connect(func(): quit(1))
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	var game := main.get_node("GameCenter/Game") as GameManager
	game._submenu_swipe_controller.duration = 0.01
	game.progression_menu.open(game._progression_snapshot())
	game.progression_menu.hide()
	game.challenge_selection.open(game.challenge_manager, [])
	game.challenge_selection.hide()
	for pixel_art: bool in [true, false]:
		game._true_pixel_art_enabled = pixel_art
		for mode: StringName in [&"menu_adaptive", &"semi_adaptive", &"adaptive"]:
			game._screen_size_mode = mode
			game.GameOptionsControllerScript.apply_resolution(game)
			for menu: Control in [game.progression_menu, game.challenge_selection]:
				await game._submenu_swipe_controller.open(menu, game._submenu_travel_distance())
				for window_size: Vector2i in [Vector2i(1908, 968), Vector2i(752, 640), Vector2i(900, 1600)]:
					root.size = window_size
					await _settle()
					var expected := game.get_global_rect() if mode != &"semi_adaptive" else game.gameplay_layer.get_global_rect()
					assert(menu.get_global_rect().is_equal_approx(expected), "%s must fill its menu canvas in %s" % [menu.name, mode])
					if mode == &"menu_adaptive":
						assert(game.gameplay_layer.size == Vector2(game.LOCKED_VIEWPORT_SIZE))
						assert(game.gameplay_layer.get_global_rect().get_center().distance_to(expected.get_center()) <= 1.0)
				await game._submenu_swipe_controller.close(menu, game._submenu_travel_distance())
				await game._submenu_swipe_controller.open(menu, game._submenu_travel_distance())
				assert(menu.get_global_rect().is_equal_approx(game.screens.get_global_rect()))
				await game._submenu_swipe_controller.close(menu, game._submenu_travel_distance())
	main.queue_free()
	await process_frame
	print("Adaptive submenu tests passed.")
	quit()


func _settle() -> void:
	for frame in 8:
		await process_frame

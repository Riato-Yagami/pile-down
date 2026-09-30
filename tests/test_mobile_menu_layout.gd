extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(40.0).timeout.connect(func(): quit(1))
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	var game := main.get_node("GameCenter/Game") as GameManager
	var menu := game.challenge_selection
	menu.open(game.challenge_manager, [])
	menu._show_page(menu.PAGE_SEEDS)
	for locale in ["fr", "en"]:
		root.get_node("LanguageSettings").apply_language(locale, false)
		for pixel_art in [true, false]:
			game._true_pixel_art_enabled = pixel_art
			for mode in [&"menu_adaptive", &"adaptive", &"semi_adaptive"]:
				game._screen_size_mode = mode
				game.GameOptionsControllerScript.apply_resolution(game)
				for window_size in [Vector2i(1080, 2424), Vector2i(1908, 968), Vector2i(752, 640)]:
					root.size = window_size
					await _settle()
					var bounds := menu.get_global_rect()
					var margin := menu.get_node("Margin") as MarginContainer
					var content := margin.get_global_rect()
					assert(content.position.x >= bounds.position.x + menu.panel_margins.x - 0.1,
						"Left minimum margin lost: %s %s %s %s" % [locale, mode, bounds, content])
					assert(content.end.x <= bounds.end.x - menu.panel_margins.z + 0.1,
						"Right minimum margin lost: %s %s %s %s" % [locale, mode, bounds, content])
					var actions := menu.seed_content.get_node("PlayASeed/Actions") as HFlowContainer
					assert(actions.size.x <= menu.seed_page.size.x,
						"Translated seed buttons must wrap inside their scroll viewport")
	# A real touch sequence must enter native edit mode without mouse emulation.
	game._screen_size_mode = &"menu_adaptive"
	game.GameOptionsControllerScript.apply_resolution(game)
	root.size = Vector2i(1080, 2424)
	await _settle()
	var input := menu._seed_input
	input.release_focus()
	input.unedit()
	var point := input.get_global_rect().get_center()
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = point
		touch.pressed = pressed
		root.push_input(touch, true)
		await process_frame
	await _settle()
	assert(input.has_focus() and input.is_editing(), "Tapping the seed must enter native editing")
	input.unedit()
	input.release_focus()
	# A canceled scroll gesture must not open the editor.
	var down := InputEventScreenTouch.new()
	down.position = point
	down.pressed = true
	root.push_input(down, true)
	var cancel := InputEventScreenTouch.new()
	cancel.position = point
	cancel.canceled = true
	root.push_input(cancel, true)
	await _settle()
	assert(not input.is_editing())
	var lamp := game.flashlight_overlay
	lamp.close_in(true)
	assert(lamp.light_position.is_equal_approx(lamp.size * 0.5))
	await _settle()
	assert(lamp.light_position.distance_to(lamp.size * 0.5) <= 1.0,
		"Idle touch lamp must not drift to the stale mouse position")
	lamp.follow_touch(Vector2(70, 110))
	await _settle()
	assert(lamp.light_position == Vector2(70, 110))
	main.queue_free()
	await process_frame
	print("Mobile menu layout, seed touch and flashlight tests passed.")
	quit()


func _settle() -> void:
	for frame in 12:
		await process_frame

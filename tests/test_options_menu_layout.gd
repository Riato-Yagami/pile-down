extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0).timeout.connect(func(): quit(1))
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	var game := main.get_node("GameCenter/Game") as GameManager
	game._screen_size_mode = &"menu_adaptive"
	game.GameOptionsControllerScript.apply_resolution(game)
	var menu := game.options_menu as OptionsMenuLayout
	menu.show()
	assert(menu.tabs_horizontal)
	for horizontal in [true, false]:
		menu.tabs_horizontal = horizontal
		for locale in ["fr", "en"]:
			root.get_node("LanguageSettings").apply_language(locale, false)
			for window_size in [Vector2i(1080, 2424), Vector2i(512, 640), Vector2i(1908, 968)]:
				root.size = window_size
				for page in range(5):
					game._show_options_page(page)
					await _settle()
					var first := menu.navigation.get_child(0) as Control
					var second := menu.navigation.get_child(1) as Control
					if horizontal:
						assert(is_equal_approx(first.position.y, second.position.y))
						assert(second.position.x > first.position.x)
					else:
						assert(is_equal_approx(first.position.x, second.position.x))
						assert(second.position.y > first.position.y)
					var margin := (menu.get_node("Margin") as Control).get_global_rect()
					assert(menu.scroll.get_global_rect().end.y <= margin.end.y + 0.1, "Content must stay inside the bottom margin")
					assert(menu.scroll.get_global_rect().end.x <= margin.end.x + 0.1, "Content must stay inside the right margin")
					assert(margin.end.y <= menu.get_global_rect().end.y - game.screen_edge_margins.w + 0.1)
					var boxes: Array[VBoxContainer] = []
					for child in menu.page.get_children():
						menu._collect_option_boxes(child, boxes)
					for box in boxes:
						var spacing := box.get_theme_constant(&"separation")
						assert(spacing >= menu.vertical_padding_min and spacing <= menu.vertical_padding_max)
	# Growing then shrinking must not retain a minimum inherited from the tall layout.
	menu.tabs_horizontal = true
	game._show_options_page(game.OPTION_GRAPHICS)
	root.size = Vector2i(1080, 2424)
	await _settle()
	var options := game.graphics_options.get_node("Content") as VBoxContainer
	menu.vertical_padding_max = 16
	menu.queue_spacing()
	await _settle()
	var roomy := options.get_theme_constant(&"separation")
	assert(roomy == menu.vertical_padding_max)
	root.size = Vector2i(512, 480)
	await _settle()
	assert(options.get_theme_constant(&"separation") < roomy, "Short screens must tighten spacing")
	menu.vertical_padding_min = 4
	menu.vertical_padding_max = 4
	menu.queue_spacing()
	await _settle()
	assert(options.get_theme_constant(&"separation") == 4)
	main.queue_free()
	await process_frame
	print("Options orientation and adaptive spacing tests passed.")
	quit()


func _settle() -> void:
	for frame in 15:
		await process_frame

extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	var game := main.get_node("GameCenter/Game") as GameManager
	game.progression_menu.open(game._progression_snapshot())
	game.challenge_selection.open(game.challenge_manager, [])
	for menu in [game.progression_menu, game.challenge_selection]:
		for horizontal in [true, false]:
			menu.tabs_horizontal = horizontal
			for window_size in [Vector2i(1080, 2424), Vector2i(512, 640), Vector2i(1908, 968)]:
				root.size = window_size
				for frame in 12:
					await process_frame
				var navigation := menu.get_node("Margin/Layout/Body/Navigation") as BoxContainer
				var first := navigation.get_child(0) as Control
				var second := navigation.get_child(1) as Control
				assert(is_zero_approx(first.position.x), "Tabs must start at the left edge")
				assert(navigation.vertical != horizontal)
				assert((second.position.x > first.position.x) == horizontal)
				assert(navigation.get_global_rect().end.x <= menu.get_global_rect().end.x - menu.panel_margins.z + 0.1, "%s horizontal=%s window=%s nav=%s menu=%s" % [menu.name, horizontal, window_size, navigation.get_global_rect(), menu.get_global_rect()])
				if menu is ProgressionMenu:
					for page in range(ProgressionMenu.Page.FONTS + 1):
						menu._on_page_button_pressed(page)
						await create_timer(0.25).timeout
						var scrolls: Array = (
							[menu.fonts_scroll, menu.palettes_scroll]
							if page == ProgressionMenu.Page.FONTS else [menu.main_scroll]
						)
						for scroll in scrolls:
							assert(scroll.is_visible_in_tree())
							assert(scroll.size.y >= 40.0,
								"Page %s horizontal=%s window=%s has a collapsed viewport: %s" % [page, horizontal, window_size, scroll.size])
							assert(menu.get_global_rect().encloses(scroll.get_global_rect()))
						if page != ProgressionMenu.Page.FONTS:
							assert(menu.content.get_child_count() > 0)
							assert(menu.main_scroll.get_global_rect().intersects(
								(menu.content.get_child(0) as Control).get_global_rect()),
								"The first entry must be visible after switching tabs")
	main.queue_free()
	await process_frame
	print("Shared menu orientation tests passed.")
	quit()

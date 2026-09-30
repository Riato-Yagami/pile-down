extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0).timeout.connect(func(): quit(1))
	root.get_node("LanguageSettings").apply_language("fr", false)
	for initial_size in [Vector2i(1080, 2424), Vector2i(1908, 968)]:
		root.size = initial_size
		var main := preload("res://resources/scenes/Main.tscn").instantiate()
		root.add_child(main)
		var game := main.get_node("GameCenter/Game") as GameManager
		game._screen_size_mode = &"menu_adaptive"
		game.GameOptionsControllerScript.apply_resolution(game)
		# Open before the first container sort, then deliver the final phone size.
		game._open_progression_menu()
		game.progression_menu.refresh({"achievements": [{
			"title": "FINAL SECONDS", "description": "Reach the shortest possible timer.",
			"unlocked": true, "new": true,
		}]})
		game.progression_menu._show_page(ProgressionMenu.Page.ACHIEVEMENTS)
		await process_frame
		root.size = Vector2i(1080, 2424)
		await create_timer(0.5).timeout
		var menu := game.progression_menu
		var bounds := menu.get_global_rect()
		var content := (menu.get_node("Margin") as Control).get_global_rect()
		assert(bounds.is_equal_approx(game.screens.get_global_rect()), "First opening must fill the menu canvas")
		assert(content.position.x >= bounds.position.x + menu.panel_margins.x - 0.1, "First opening must preserve the left margin")
		assert(content.end.x <= bounds.end.x - menu.panel_margins.z + 0.1, "First opening must preserve the right margin")
		var entry := menu.content.get_child(1) as VBoxContainer
		var heading_row := entry.get_child(0) as HBoxContainer
		var heading := heading_row.get_child(heading_row.get_child_count() - 1) as Label
		assert(heading_row.has_node("NewLabel"), "The regression requires an unread achievement")
		assert(heading.get_line_count() > 1, "The title must wrap beside the French NEW badge")
		assert(heading.get_global_rect().end.x <= content.end.x, "The full title must remain inside the margins")
		main.queue_free()
		await process_frame
	print("First menu opening tests passed.")
	quit()

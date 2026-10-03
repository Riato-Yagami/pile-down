extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(15.0).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	var tabs: Array[BaseButton] = [
		game.gameplay_options_button, game.sound_options_button,
		game.graphics_options_button, game.save_options_button, game.links_options_button,
	]
	for page in tabs.size():
		game._options_page = page
		game._open_options_menu()
		await create_timer(0.3).timeout
		assert(root.gui_get_focus_owner() == tabs[page], "Opening options must focus the tab, not a setting")
		if page == game.OPTION_SOUND:
			var label := game.music_volume_slider.get_parent().get_child(0) as Label
			assert(label.get_theme_color("font_color") == game.OPTION_TEXT_COLOR)
			game.music_volume_slider.grab_focus()
			assert(label.get_theme_color("font_color") == game.OPTIONS_SELECTED_COLOR,
				"Deliberate keyboard focus must still highlight the setting")
			game._open_options_menu()
			assert(label.get_theme_color("font_color") == game.OPTION_TEXT_COLOR)
		await game._close_options_menu()
	game.queue_free()
	await process_frame
	print("Options open without automatically highlighting their first setting.")
	quit()

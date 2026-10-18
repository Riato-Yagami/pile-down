extends SceneTree

const MainScene := preload("res://resources/scenes/Main.tscn")
const ScreenSizes := preload("res://resources/scripts/settings/display/ScreenSizeOptions.gd")

var main: Control


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(40.0).timeout.connect(func() -> void: quit(1))
	var config := SaveConfig.load_current()
	if config.has_section("graphics"):
		config.erase_section("graphics")
	assert(config.save(SaveConfig.PATH) == OK)
	root.size = Vector2i(960, 720)
	var game := await _open_game()
	assert(game.start_adaptive_in_editor)
	assert(game._screen_size_mode == ScreenSizes.SCREEN_SIZE_MODE_MENU_ADAPTIVE)
	for mode_index in ScreenSizes.SCREEN_SIZE_MODES.size():
		var expected_mode: StringName = ScreenSizes.SCREEN_SIZE_MODES[mode_index]
		for pixel_art in [false, true]:
			game._show_options_page(GameManager.OPTION_GRAPHICS)
			var selector := game.adaptive_resolution_button.get_parent().get_node("ScreenSizeModeSelector") as OptionButton
			selector.item_selected.emit(mode_index)
			if game._true_pixel_art_enabled != pixel_art:
				game.true_pixel_art_button.pressed.emit()
			var background_enabled := mode_index % 2 == 0
			if game._background_enabled != background_enabled:
				game.background_enabled_button.pressed.emit()
			config = SaveConfig.load_current()
			assert(StringName(config.get_value("graphics", "screen_size_mode")) == expected_mode)
			assert(config.get_value("graphics", "true_pixel_art", false) == pixel_art)
			await _close_game()
			game = await _open_game()
			assert(game._screen_size_mode == expected_mode,
				"Reopening must restore %s despite the editor default" % expected_mode)
			assert(game._true_pixel_art_enabled == pixel_art)
			assert(game._background_enabled == background_enabled)
			assert(root.content_scale_mode == (
				Window.CONTENT_SCALE_MODE_VIEWPORT if pixel_art else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			))
			assert(root.content_scale_aspect == (
				Window.CONTENT_SCALE_ASPECT_KEEP if expected_mode == ScreenSizes.SCREEN_SIZE_MODE_CLASSIC
				else Window.CONTENT_SCALE_ASPECT_EXPAND
			))
			game._show_options_page(GameManager.OPTION_GRAPHICS)
			selector = game.adaptive_resolution_button.get_parent().get_node("ScreenSizeModeSelector") as OptionButton
			assert(selector.selected == mode_index)
	# Older saves contain only the adaptive boolean and must also take priority.
	for adaptive in [false, true]:
		await _close_game()
		config = SaveConfig.load_current()
		if config.has_section_key("graphics", "screen_size_mode"):
			config.erase_section_key("graphics", "screen_size_mode")
		config.set_value("graphics", "adaptive_resolution", adaptive)
		assert(config.save(SaveConfig.PATH) == OK)
		game = await _open_game()
		assert(game._screen_size_mode == (
			ScreenSizes.SCREEN_SIZE_MODE_ADAPTIVE if adaptive else ScreenSizes.SCREEN_SIZE_MODE_CLASSIC
		))
	await _close_game()
	print("Display settings persistence tests passed.")
	quit()


func _open_game() -> GameManager:
	main = MainScene.instantiate() as Control
	root.add_child(main)
	for frame in 8:
		await process_frame
	return main.get_node("GameCenter/Game") as GameManager


func _close_game() -> void:
	main.queue_free()
	await process_frame
	await process_frame

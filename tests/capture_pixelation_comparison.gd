extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1024, 1280)
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	var game := main.get_node("GameCenter/Game") as GameManager
	game._screen_size_mode = &"adaptive"
	game.start_game(false)
	while game.input_locked:
		await process_frame
	game.timer_manager.stop_countdown()
	game.debug_help.visible = false
	var bg := BackgroundThemeRegistry.find(&"grid")
	game.background_manager.transition_to(bg)
	game.background_manager.skip_transition()
	for frame in 120:
		await process_frame
	main.process_mode = Node.PROCESS_MODE_DISABLED
	var overlay := game.special_rule_manager.pixelation_overlay as PixelationOverlay
	overlay.transition_duration = 0.0
	var output_dir := "res://build/tmp/pixelation-comparison"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	for mode in [false, true]:
		game._true_pixel_art_enabled = mode
		game.GameOptionsControllerScript.apply_resolution(game)
		game.debug_help.visible = false
		for enabled in [false, true]:
			if enabled:
				overlay.show_pixelation(DifficultySettings.PIXELATION_PIXEL_SIZE)
			else:
				overlay.hide_pixelation(false)
			for frame in 12:
				await process_frame
			await RenderingServer.frame_post_draw
			var capture := root.get_texture().get_image()
			capture.resize(1024, 1280, Image.INTERPOLATE_NEAREST)
			capture.save_png(output_dir.path_join("true-%s-effect-%s.png" % [mode, enabled]))
			print("capture true=", mode, " effect=", enabled, " viewport=", root.get_visible_rect(), " overlay=", overlay.size, " material=", overlay.material)
	quit()

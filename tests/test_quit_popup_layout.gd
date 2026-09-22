extends SceneTree

const MAIN_SCENE := preload("res://resources/scenes/Main.tscn")
const Options := preload("res://resources/scripts/settings/GameOptionsController.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(512, 640)
	var main := MAIN_SCENE.instantiate() as Control
	root.add_child(main)
	await _settle_layout()
	var game := main.get_node("GameCenter/Game") as GameManager
	game.splash.hide()
	game.overlay.hide()
	game._screen_size_mode = Options.SCREEN_SIZE_MODE_SEMI_ADAPTIVE
	for pixel_art in [true, false]:
		game._true_pixel_art_enabled = pixel_art
		Options.apply_resolution(game)
		await _settle_layout()
		for window_size in [Vector2i(1908, 968), Vector2i(600, 1000), Vector2i(512, 640)]:
			root.size = window_size
			await _settle_layout()
			for seeded in [false, true]:
				game.run_uses_requested_seed = seeded
				game._open_quit_popup()
				await _settle_layout()
				assert(_is_centered(game), "Quit popup must be centered on reopening.")
				game._close_quit_popup()
		# Keep the popup open during another resize.
		game._open_quit_popup()
		root.size = Vector2i(1500, 900)
		await _settle_layout()
		assert(_is_centered(game), "Quit popup must stay centered while resizing.")
		game._close_quit_popup()
	main.queue_free()
	await process_frame
	print("Quit popup layout test passed.")
	quit()


func _settle_layout() -> void:
	for frame in 5:
		await process_frame


func _is_centered(game: GameManager) -> bool:
	var viewport_rect := game.get_viewport_rect()
	if not game.quit_popup.get_global_rect().is_equal_approx(viewport_rect):
		return false
	var margins := game.screen_edge_margins
	var expected_center := viewport_rect.get_center() + Vector2(
		margins.x - margins.z, margins.y - margins.w
	) * 0.5
	return game.quit_panel.get_global_rect().get_center().distance_to(expected_center) <= 1.0

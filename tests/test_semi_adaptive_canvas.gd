extends SceneTree

const MainScene := preload("res://resources/scenes/Main.tscn")
const Options := preload("res://resources/scripts/settings/GameOptionsController.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for pixel_art in [true, false]:
		for window_size in [Vector2i(1908, 968), Vector2i(1068, 1808)]:
			await _check_return_transition(window_size, pixel_art)
	print("Semi adaptive canvas tests passed.")
	quit()


func _check_return_transition(window_size: Vector2i, pixel_art: bool) -> void:
	root.size = Vector2i(1908, 968)
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame
	var game := main.get_node("GameCenter/Game") as GameManager
	assert(not game.gameplay_layer.visible)
	game._true_pixel_art_enabled = pixel_art
	game._screen_size_mode = Options.SCREEN_SIZE_MODE_SEMI_ADAPTIVE
	Options.apply_resolution(game)
	root.size = window_size
	for frame in 5:
		await process_frame
	var artwork := game.get_node("Artwork") as Control
	var background := artwork.get_node("BackgroundArt") as ColorRect
	var stripe_material := background.material as ShaderMaterial
	var splash_background := game.get_node("Screens/Splash/Background") as ColorRect
	if pixel_art and window_size == Vector2i(1908, 968):
		assert(artwork.get_global_rect().is_equal_approx(game.get_global_rect()))
		assert(background.get_global_rect().is_equal_approx(game.get_global_rect()))
	assert(is_equal_approx(float(
		stripe_material.get_shader_parameter("effect_enabled")
	), 1.0))
	assert(splash_background.visible)
	assert(splash_background.get_global_rect().is_equal_approx(game.get_global_rect()))
	assert(not game.gameplay_layer.visible)
	var menu_buttons: Array[Control] = [
		game.challenge_button, game.options_button, game.progression_button,
	]
	var resting_button_positions: Array[Vector2] = []
	for button in menu_buttons:
		resting_button_positions.append(button.get_global_rect().position)
	game.overlay.visible = true
	game._fit_overlay_to_canvas()
	assert(game.overlay.get_global_rect().is_equal_approx(game.get_global_rect()))
	assert(game.overlay_scrim.get_global_rect().is_equal_approx(game.get_global_rect()))
	game.overlay.visible = false
	game.splash.visible = false
	game.start_game()
	assert(game.gameplay_layer.visible)
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)
	game._return_to_menu()
	await process_frame
	assert(game.splash.get_parent() == game.menu_transition_layer)
	assert(is_equal_approx(
		splash_background.get_global_rect().position.x,
		game.get_global_rect().position.x
	))
	deadline = Time.get_ticks_msec() + 3000
	while game._screen_transition_active and Time.get_ticks_msec() < deadline:
		# A window layout refresh must not stretch or recenter the sliding menu.
		Options.apply_low_resolution_layout(game)
		assert(game.splash.size.is_equal_approx(game.screens.size))
		var slide_offset := game.splash.position.y - game.screens.position.y
		for index in menu_buttons.size():
			var expected := resting_button_positions[index] + Vector2(0.0, slide_offset)
			assert(menu_buttons[index].get_global_rect().position.is_equal_approx(expected))
		await process_frame
	assert(not game._screen_transition_active)
	assert(game.splash.get_parent() == game.screens)
	assert(game.splash.position == Vector2.ZERO)
	assert(game.splash.size == game.screens.size)
	for index in menu_buttons.size():
		assert(menu_buttons[index].get_global_rect().position.is_equal_approx(
			resting_button_positions[index]
		))
	assert(not game.gameplay_layer.visible)
	main.queue_free()
	await process_frame

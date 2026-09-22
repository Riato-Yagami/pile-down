extends SceneTree

const MAIN_SCENE := preload("res://resources/scenes/Main.tscn")
const GAME_SCENE := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(480, 320)
	var main := MAIN_SCENE.instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame
	var game_center := main.get_node("GameCenter") as Control
	var game := game_center.get_node("Game") as Control
	var screens := game.get_node("Screens") as Control
	var artwork := game.get_node("Artwork") as Control
	var background := artwork.get_node("BackgroundArt") as ColorRect
	var stripe_material := background.material as ShaderMaterial
	print("adaptive rects: viewport=", root.size, " main=", main.size,
		" center=", game_center.size, " game=", game.size,
		" game_global=", game.global_position,
		" screens=", screens.get_global_rect(),
		" artwork=", artwork.size, " background=", background.size)
	assert(main.size == Vector2(480, 320))
	assert(game.size == main.size)
	assert(screens.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(is_equal_approx(
		screens.get_global_rect().get_center().x,
		main.size.x * 0.5
	))
	assert(is_equal_approx(float(
		stripe_material.get_shader_parameter("effect_enabled")
	), 1.0))
	assert(artwork.global_position == Vector2.ZERO)
	assert(artwork.size == main.size)
	assert(background.size == main.size)
	assert(stripe_material.get_shader_parameter("viewport_size") == main.size)
	var overlay := game.get_node("Screens/Overlay") as Control
	var overlay_scrim := overlay.get_node("Scrim") as ColorRect
	var splash_background := game.get_node("Screens/Splash/Background") as ColorRect
	assert(overlay.get_global_rect() == game.get_global_rect())
	assert(overlay_scrim.get_global_rect() == game.get_global_rect())
	assert(splash_background.visible)
	assert(splash_background.get_global_rect() == game.get_global_rect())
	root.size = Vector2i(640, 360)
	await process_frame
	await process_frame
	print("resized adaptive rects: viewport=", root.size, " main=", main.size,
		" game_global=", game.global_position,
		" screens=", screens.get_global_rect(),
		" artwork=", artwork.size, " background=", background.size)
	assert(game.size == main.size)
	assert(is_equal_approx(
		screens.get_global_rect().get_center().x,
		main.size.x * 0.5
	))
	assert(artwork.global_position == Vector2.ZERO)
	assert(artwork.size == main.size)
	assert(background.size == artwork.size)
	assert(
		stripe_material.get_shader_parameter("viewport_size")
		== artwork.size
	)
	root.size = Vector2i(1908, 968)
	await process_frame
	await process_frame
	print("wide adaptive rects: viewport=", root.size, " main=", main.size,
		" game_global=", game.global_position,
		" screens=", screens.get_global_rect(),
		" artwork=", artwork.size, " background=", background.size)
	assert(is_equal_approx(
		screens.get_global_rect().get_center().x,
		main.size.x * 0.5
	))
	assert(artwork.global_position == Vector2.ZERO)
	assert(artwork.size == main.size)
	assert(background.size == artwork.size)
	main.queue_free()
	await process_frame
	var standalone_game := GAME_SCENE.instantiate() as Control
	root.add_child(standalone_game)
	await process_frame
	await process_frame
	var standalone_board := standalone_game.get_node("Gameplay/PilesBoard") as Control
	var standalone_artwork := standalone_game.get_node("Artwork") as Control
	var standalone_screens := standalone_game.get_node("Screens") as Control
	print("standalone rects: game=", standalone_game.size,
		" screens=", standalone_screens.get_global_rect(),
		" board=", standalone_board.get_global_rect(),
		" artwork=", standalone_artwork.get_global_rect())
	assert(standalone_board.size == Vector2(164, 163))
	var standalone_background := standalone_artwork.get_node("BackgroundArt") as ColorRect
	var standalone_stripe_material := standalone_background.material as ShaderMaterial
	assert(
		standalone_stripe_material.get_shader_parameter("viewport_size")
		== standalone_artwork.size
	)
	assert(is_equal_approx(
		standalone_board.get_global_rect().get_center().x,
		standalone_game.size.x * 0.5
	))
	assert(is_equal_approx(
		standalone_screens.get_global_rect().get_center().x,
		standalone_game.size.x * 0.5
	))
	quit()

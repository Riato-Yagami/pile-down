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
	var artwork := game.get_node("Artwork") as Control
	var background := artwork.get_node("BackgroundArt") as ColorRect
	print("adaptive rects: viewport=", root.size, " main=", main.size,
		" center=", game_center.size, " game=", game.size,
		" artwork=", artwork.size, " background=", background.size)
	assert(main.size == Vector2(480, 320))
	assert(game.size == Vector2(256, 320))
	assert(artwork.global_position == Vector2.ZERO)
	assert(artwork.size == main.size)
	assert(background.size == main.size)
	var stripe_material := background.material as ShaderMaterial
	assert(stripe_material.get_shader_parameter("viewport_size") == main.size)
	root.size = Vector2i(640, 360)
	await process_frame
	await process_frame
	print("resized adaptive rects: viewport=", root.size, " main=", main.size,
		" artwork=", artwork.size, " background=", background.size)
	assert(game.size == Vector2(256, 320))
	assert(artwork.global_position == Vector2.ZERO)
	assert(artwork.size == main.size)
	assert(background.size == artwork.size)
	assert(
		stripe_material.get_shader_parameter("viewport_size")
		== artwork.size
	)
	main.queue_free()
	await process_frame
	var standalone_game := GAME_SCENE.instantiate() as Control
	root.add_child(standalone_game)
	await process_frame
	await process_frame
	var standalone_board := standalone_game.get_node("Gameplay/PilesBoard") as Control
	var standalone_artwork := standalone_game.get_node("Artwork") as Control
	print("standalone rects: game=", standalone_game.size,
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
	quit()

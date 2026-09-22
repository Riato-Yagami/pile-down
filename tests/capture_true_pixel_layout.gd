extends SceneTree

const MainScene := preload("res://resources/scenes/Main.tscn")
const GameOptionsController := preload(
	"res://resources/scripts/settings/GameOptionsController.gd"
)
const BackgroundThemeRegistry := preload(
	"res://resources/scripts/backgrounds/BackgroundThemeRegistry.gd"
)

const BACKGROUND_IDS: Array[StringName] = [
	&"stripes",
	&"grid",
	&"dots",
	&"waves",
	&"diamonds",
]
const ASPECT_CHECK_SIZES: Array[Vector2i] = [
	Vector2i(760, 640),
	Vector2i(1893, 640),
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(752, 640)
	await _capture_options_combinations()
	await _capture_gameplay_combinations()
	await _capture_background_aspects()
	quit()


func _capture_options_combinations() -> void:
	for adaptive in [false, true]:
		for true_pixel in [false, true]:
			var main := MainScene.instantiate()
			root.add_child(main)
			var game := main.get_node("GameCenter/Game") as GameManager
			game._adaptive_resolution = adaptive
			game._true_pixel_art_enabled = true_pixel
			GameOptionsController.apply_resolution(game)
			for frame in 8:
				await process_frame
			game.splash.visible = true
			game.options_menu.visible = true
			game._show_options_page(game.OPTION_GRAPHICS, false)
			for frame in 4:
				await process_frame
			_print_options_rects(game, adaptive, true_pixel)
			_capture("options-adaptive-%s-tpa-%s.png" % [adaptive, true_pixel])
			main.queue_free()
			for frame in 2:
				await process_frame


func _capture_gameplay_combinations() -> void:
	for adaptive in [false, true]:
		for true_pixel in [false, true]:
			var main := MainScene.instantiate()
			root.add_child(main)
			var game := main.get_node("GameCenter/Game") as GameManager
			game._adaptive_resolution = adaptive
			game._true_pixel_art_enabled = true_pixel
			GameOptionsController.apply_resolution(game)
			for frame in 8:
				await process_frame
			game.start_game(false)
			for frame in 200:
				await process_frame
				if not game.input_locked:
					break
			for frame in 12:
				await process_frame
			_print_gameplay_combination_rects(game, adaptive, true_pixel)
			_capture("gameplay-adaptive-%s-tpa-%s.png" % [adaptive, true_pixel])
			main.queue_free()
			for frame in 2:
				await process_frame


func _capture_background_aspects() -> void:
	for viewport_size in ASPECT_CHECK_SIZES:
		root.size = viewport_size
		for background_id in BACKGROUND_IDS:
			var main := MainScene.instantiate()
			root.add_child(main)
			var game := main.get_node("GameCenter/Game") as GameManager
			game._adaptive_resolution = true
			game._true_pixel_art_enabled = false
			GameOptionsController.apply_resolution(game)
			for frame in 8:
				await process_frame
			game.start_game(false)
			for frame in 200:
				await process_frame
				if not game.input_locked:
					break
			var background_data := BackgroundThemeRegistry.find(background_id)
			game.background_manager.transition_to(background_data)
			game.background_manager.skip_transition()
			for frame in 12:
				await process_frame
			_print_background_aspect_rects(game, background_id, viewport_size)
			_capture("background-%s-%dx%d.png" % [
				background_id, viewport_size.x, viewport_size.y
			])
			main.queue_free()
			for frame in 2:
				await process_frame
	root.size = Vector2i(752, 640)


func _run_previous_capture() -> void:
	root.size = Vector2i(752, 640)
	var main := MainScene.instantiate()
	root.add_child(main)
	var game := main.get_node("GameCenter/Game") as GameManager
	game._adaptive_resolution = true
	game._true_pixel_art_enabled = true
	GameOptionsController.apply_resolution(game)
	for frame in 8:
		await process_frame
	game.splash.visible = true
	game.quit_popup.visible = false
	for frame in 4:
		await process_frame
	_print_rects(game)
	_capture("true-pixel-menu-before.png")
	game.splash.visible = false
	game.back_button.visible = true
	game.quit_popup.visible = true
	for frame in 2:
		await process_frame
	_capture("true-pixel-escape-before.png")
	game.quit_popup.visible = false
	game.start_game(false)
	for frame in 180:
		await process_frame
		if not game.input_locked:
			break
	for frame in 4:
		await process_frame
	_print_gameplay_rects(game)
	_capture("true-pixel-gameplay-before.png")


func _print_rects(game: GameManager) -> void:
	var content := game.get_node("Screens/Splash/Center/Content") as Control
	var title := game.get_node("Screens/Splash/Center/Content/Title") as Control
	var high_score := game.get_node("Screens/Splash/Center/Content/HighScoreArea") as Control
	var buttons := game.get_node("Screens/Splash/Center/Content/RunButtons") as Control
	print("root_size=", root.size)
	print("window_size=", game.get_window().size)
	print("game pos/scale/size=", game.position, " ", game.scale, " ", game.size)
	print("screens pos/scale/size=", game.screens.position, " ", game.screens.scale, " ", game.screens.size)
	print("splash pos/scale/size=", game.splash.position, " ", game.splash.scale, " ", game.splash.size)
	print("content global_rect=", content.get_global_rect())
	print("title global_rect=", title.get_global_rect())
	print("high_score global_rect=", high_score.get_global_rect())
	print("buttons global_rect=", buttons.get_global_rect())


func _print_options_rects(
	game: GameManager,
	adaptive: bool,
	true_pixel: bool
) -> void:
	var layout := game.get_node(
		"Screens/Splash/OptionsMenu/Margin/Layout"
	) as Control
	var margin := game.get_node(
		"Screens/Splash/OptionsMenu/Margin"
	) as Control
	print("--- options adaptive=", adaptive, " tpa=", true_pixel)
	print("root_size=", root.size, " window_size=", game.get_window().size)
	print("content_scale_mode=", game.get_window().content_scale_mode)
	print("game pos/scale/size=", game.position, " ", game.scale, " ", game.size)
	print("screens pos/scale/size=", game.screens.position, " ", game.screens.scale, " ", game.screens.size)
	print("splash pos/scale/size=", game.splash.position, " ", game.splash.scale, " ", game.splash.size)
	print("options pos/scale/size=", game.options_menu.position, " ", game.options_menu.scale, " ", game.options_menu.size)
	print("margin global_rect=", margin.get_global_rect())
	print("layout global_rect=", layout.get_global_rect())


func _print_gameplay_combination_rects(
	game: GameManager,
	adaptive: bool,
	true_pixel: bool
) -> void:
	print("--- gameplay adaptive=", adaptive, " tpa=", true_pixel)
	print("root_size=", root.size, " window_size=", game.get_window().size)
	print("content_scale_mode=", game.get_window().content_scale_mode)
	print("game pos/scale/size=", game.position, " ", game.scale, " ", game.size)
	print("gameplay pos/scale/size=", game.gameplay_layer.position, " ", game.gameplay_layer.scale, " ", game.gameplay_layer.size)
	print("piles_board global_rect=", game.piles_board.get_global_rect())
	print("hand_tray global_rect=", game.hand_tray.get_global_rect())
	print("timer global_rect=", game.timer_ring.get_global_rect())
	print("round global_rect=", game.round_panel.get_global_rect())
	print("background effects pixel size=", _background_effects_pixel_size(game))
	print("shader backgrounds pixelated=", game.background_manager.pixelated_backgrounds)


func _print_background_aspect_rects(
	game: GameManager,
	background_id: StringName,
	viewport_size: Vector2i
) -> void:
	print("--- background ", background_id, " size=", viewport_size)
	print("root_size=", root.size, " window_size=", game.get_window().size)
	print("content_scale_mode=", game.get_window().content_scale_mode)
	if game.background_manager.current_layer != null:
		print("current layer rect=", game.background_manager.current_layer.get_global_rect())
		print("shader backgrounds pixelated=", game.background_manager.pixelated_backgrounds)
	print("background effects pixel size=", _background_effects_pixel_size(game))


func _background_effects_pixel_size(game: GameManager) -> float:
	if not is_instance_valid(game.background_effects):
		return 0.0
	var material := game.background_effects._shader_material as ShaderMaterial
	if material == null:
		return 0.0
	return float(material.get_shader_parameter("pixel_size"))


func _print_gameplay_rects(game: GameManager) -> void:
	print("gameplay pos/scale/size=", game.gameplay_layer.position, " ", game.gameplay_layer.scale, " ", game.gameplay_layer.size)
	print("piles_board global_rect=", game.piles_board.get_global_rect())
	print("hand_tray global_rect=", game.hand_tray.get_global_rect())
	print("timer global_rect=", game.timer_ring.get_global_rect())
	print("round global_rect=", game.round_panel.get_global_rect())


func _capture(file_name: String) -> void:
	var output_dir := ProjectSettings.globalize_path("res://build/tmp/screenshots")
	DirAccess.make_dir_recursive_absolute(output_dir)
	if DisplayServer.get_name() == "headless":
		print("capture skipped in headless mode: %s" % output_dir.path_join(file_name))
		return
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		print("capture skipped in headless mode: %s" % output_dir.path_join(file_name))
		return
	var image := viewport_texture.get_image()
	if image == null:
		print("capture skipped without viewport image: %s" % output_dir.path_join(file_name))
		return
	var error := image.save_png(output_dir.path_join(file_name))
	assert(error == OK)

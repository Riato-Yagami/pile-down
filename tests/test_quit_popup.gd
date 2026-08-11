extends SceneTree

const GAME_SCENE := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GAME_SCENE.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)
	assert(not game.quit_popup.visible)
	game._open_quit_popup()
	assert(game.quit_popup.visible)
	var quit_layer := game.quit_popup.get_parent() as CanvasLayer
	var pixelation_layer := game.get_node("PresentationLayers/PixelationLayer") as CanvasLayer
	assert(quit_layer != null)
	assert(quit_layer.layer > pixelation_layer.layer)
	assert(game.quit_popup.get_node_or_null("Center/Panel/Content/Title") == null)
	assert(game.quit_continue_button.text == "CONTINUE")
	assert(game.quit_restart_button.text == "RESTART")
	assert(game.quit_run_button.text == "QUIT")
	assert(not game.quit_restart_button.has_focus())
	assert(not game.quit_run_button.has_focus())
	assert(game.quit_popup.get_node("Center/Panel") is NinePatchRect)
	assert(game.quit_continue_button.get_parent() is VBoxContainer)
	assert(game.quit_continue_button.custom_minimum_size == Vector2(110, 31))
	assert(game.quit_continue_button.get_theme_font_size("font_size") == 20)
	game.quit_continue_button.pressed.emit()
	assert(not game.quit_popup.visible)
	game._open_quit_popup()
	var round_time_before := game.timer_manager.time_left
	var run_time_before := game._total_time_milliseconds()
	await create_timer(0.2).timeout
	assert(game.timer_manager.time_left < round_time_before)
	assert(game._total_time_milliseconds() > run_time_before)
	assert(not game.input_locked)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	assert(game._handle_global_shortcut(escape))
	assert(not game.quit_popup.visible)
	game.pile_count = DifficultySettings.START_PILES + 1
	game._open_quit_popup()
	var restart := InputEventKey.new()
	restart.keycode = KEY_R
	restart.pressed = true
	assert(game._handle_global_shortcut(restart))
	await process_frame
	assert(not game.quit_popup.visible)
	assert(game.pile_count == DifficultySettings.START_PILES)
	game.queue_free()
	await process_frame
	print("Quit popup test passed.")
	quit()

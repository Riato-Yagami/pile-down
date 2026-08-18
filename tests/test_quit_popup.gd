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
	assert(not game.pause_seed_display.visible)
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
	game.special_rule_manager.pixelation_overlay.show_pixelation(4.0)
	assert(game.special_rule_manager.pixelation_overlay.visible)
	game.bonus_manager.offer_bonus_choice(10)
	await process_frame
	assert(game.bonus_selection.visible)
	game.special_rule_manager.announcement.show_rules([
		SpecialRuleRegistry.create_all_rules()[0]
	])
	await process_frame
	assert(game.special_rule_manager.announcement.visible)
	game._open_quit_popup()
	var restart := InputEventKey.new()
	restart.keycode = KEY_R
	restart.pressed = true
	assert(game._handle_global_shortcut(restart))
	await process_frame
	assert(game.quit_popup.visible)
	assert(game._screen_transition_active)
	assert(game.replay_transition_mask.visible)
	assert(game.bonus_selection.visible)
	assert(game.special_rule_manager.announcement.visible)
	deadline = Time.get_ticks_msec() + 3000
	while game._screen_transition_active and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game._screen_transition_active)
	assert(not game.replay_transition_mask.visible)
	assert(not game.bonus_selection.visible)
	assert(not game.special_rule_manager.announcement.visible)
	assert(not game.special_rule_manager.pixelation_overlay.visible)
	assert(game.pile_count == DifficultySettings.START_PILES)
	assert(not game.quit_popup.visible)
	deadline = Time.get_ticks_msec() + 5000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)
	assert(not game.piles.is_empty())
	assert(game.timer_manager.running)
	game.bonus_manager.offer_bonus_choice(10)
	await process_frame
	assert(game.bonus_selection.visible)
	game.special_rule_manager.announcement.show_rules([
		SpecialRuleRegistry.create_all_rules()[0]
	])
	await process_frame
	assert(game.special_rule_manager.announcement.visible)
	game._open_quit_popup()
	game._return_to_menu()
	await process_frame
	assert(game.quit_popup.visible)
	assert(game.bonus_selection.visible)
	assert(game.special_rule_manager.announcement.visible)
	assert(game.menu_transition_layer.layer > quit_layer.layer)
	deadline = Time.get_ticks_msec() + 3000
	while game._screen_transition_active and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(is_instance_valid(game))
	assert(game.splash.visible)
	assert(game.splash.get_parent() == game.screens)
	assert(not game.quit_popup.visible)
	assert(not game.bonus_selection.visible)
	assert(not game.special_rule_manager.announcement.visible)
	assert(not game.overlay.visible)
	assert(not game.active_bonus_bar.visible)
	assert(game.bonus_manager.active.is_empty())
	assert(not game.back_button.visible)
	assert(game.music_manager.is_playing_menu_music())
	game.queue_free()
	await process_frame
	print("Quit popup test passed.")
	quit()

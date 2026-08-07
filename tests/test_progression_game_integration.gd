extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	await process_frame
	assert(game.hand_tray is NinePatchRect)
	assert(game.start_adaptive_in_editor)
	assert(game.hand_tray.patch_margin_left == 18)
	assert(game.hand_tray.patch_margin_right == 18)
	assert(game.back_button.anchor_left == 1.0)
	assert(game.back_button.anchor_right == 1.0)
	assert(game.options_button.texture_normal != null)
	assert(game.splash_debug_help.visible == game.Debug.is_enabled())
	assert(game.splash_debug_help.text.contains("[U] TOGGLE UNLOCK EVERYTHING"))
	assert(game.splash_debug_help.text.contains("[E] WIN CURRENT ROUND"))
	game.options_button.pressed.emit()
	await process_frame
	assert(game.options_menu.visible)
	assert(game.options_back_button is TextureButton)
	assert(game.options_back_button.texture_normal != null)
	var options_title := game.get_node(
		"Screens/Splash/OptionsMenu/Margin/Layout/Header/Title"
	) as Label
	assert(options_title.text == "OPTIONS")
	assert(options_title.position.x < game.options_back_button.position.x)
	assert(game.options_menu.is_ancestor_of(game.music_volume_slider))
	assert(
		is_equal_approx(
			game.music_volume_slider.position.x,
			game.sound_volume_slider.position.x
		)
	)
	assert(
		is_equal_approx(
			game.music_volume_slider.size.x,
			game.sound_volume_slider.size.x
		)
	)
	assert(game.options_page_title.text == "GAMEPLAY")
	assert(game.gameplay_options.visible)
	assert(game.gameplay_options_button.texture_normal != null)
	assert(game.achievement_notifications_button.icon == game.SELECTED_TEXTURE)
	assert(game.timer_display_button.icon == game.SELECTED_TEXTURE)
	game.timer_display_button.pressed.emit()
	assert(not game.run_time_label.visible)
	assert(game.timer_label.visible)
	assert(game.timer_display_button.icon == game.UNCHECKED_TEXTURE)
	game.timer_display_button.pressed.emit()
	assert(game.run_time_label.visible == not game.splash.visible)
	assert(game.timer_label.visible)
	var audio_child_count := game.soft_audio.get_child_count()
	game.achievement_manager.achievement_unlocked.emit(
		AchievementRegistry.create_all()[7]
	)
	assert(game.achievement_popup.visible)
	assert(game.achievement_popup_title.text.contains("NO SHORTCUTS"))
	assert(game.soft_audio.get_child_count() > audio_child_count)
	await create_timer(0.35).timeout
	game.achievement_notifications_button.pressed.emit()
	assert(not game.achievement_popup.visible)
	assert(game.achievement_notifications_button.icon == game.UNCHECKED_TEXTURE)
	await create_timer(1.7).timeout
	assert(not game._achievement_notification_active)
	game.achievement_notifications_button.pressed.emit()
	game.sound_options_button.pressed.emit()
	assert(game.options_page_title.text == "SOUND")
	assert(game.sound_options.visible)
	assert(game.sound_options is VBoxContainer)
	assert(not game.gameplay_options.visible)
	assert(not game.graphics_options.visible)
	assert(not game.save_options.visible)
	game.graphics_options_button.pressed.emit()
	assert(game.options_page_title.text == "GRAPHICS")
	assert(game.graphics_options.visible)
	assert(not game.gameplay_options.visible)
	assert(not game.sound_options.visible)
	assert(not game.save_options.visible)
	assert(game.graphics_options is VBoxContainer)
	assert(game.adaptive_resolution_button.flat)
	assert(game.locked_resolution_button.flat)
	assert(game.adaptive_resolution_button is HighlightButton)
	assert(game.locked_resolution_button is HighlightButton)
	assert(
		game.adaptive_resolution_button.get_theme_color("font_color")
		== game.OPTION_TEXT_COLOR
	)
	assert(
		game.locked_resolution_button.get_theme_color("font_hover_color")
		== game.OPTIONS_SELECTED_COLOR
	)
	game.locked_resolution_button.pressed.emit()
	assert(game.get_window().content_scale_size == Vector2i(256, 320))
	assert(game.adaptive_resolution_button.icon == game.UNCHECKED_TEXTURE)
	assert(game.locked_resolution_button.icon == game.SELECTED_TEXTURE)
	assert(game.locked_resolution_button.modulate == Color.WHITE)
	game.adaptive_resolution_button.pressed.emit()
	assert(
		game.get_window().content_scale_mode
		== Window.CONTENT_SCALE_MODE_VIEWPORT
	)
	assert(game.get_window().content_scale_size == Vector2i(256, 320))
	assert(
		game.get_window().content_scale_aspect
		== Window.CONTENT_SCALE_ASPECT_EXPAND
	)
	assert(game.adaptive_resolution_button.icon == game.SELECTED_TEXTURE)
	assert(game.locked_resolution_button.icon == game.UNCHECKED_TEXTURE)
	game.locked_resolution_button.pressed.emit()
	assert(
		game.get_window().content_scale_mode
		== Window.CONTENT_SCALE_MODE_VIEWPORT
	)
	assert(game.get_window().content_scale_size == Vector2i(256, 320))
	assert(
		game.get_window().content_scale_aspect
		== Window.CONTENT_SCALE_ASPECT_KEEP
	)
	assert(game.adaptive_resolution_button.icon == game.UNCHECKED_TEXTURE)
	assert(game.locked_resolution_button.icon == game.SELECTED_TEXTURE)
	game.save_options_button.pressed.emit()
	assert(game.options_page_title.text == "SAVE DATA")
	assert(not game.gameplay_options.visible)
	assert(not game.sound_options.visible)
	assert(game.save_options.visible)
	assert(game.save_options is VBoxContainer)
	assert(game.export_save_button.flat)
	assert(game.import_save_button.flat)
	assert(game.delete_save_button.flat)
	assert(game.export_save_button is HighlightButton)
	assert(
		game.export_save_button.get_theme_color("font_color")
		== game.OPTION_TEXT_COLOR
	)
	assert(
		game.delete_save_button.get_theme_color("font_hover_color")
		== game.OPTIONS_SELECTED_COLOR
	)
	assert(game.export_save_dialog.use_native_dialog)
	assert(
		game.delete_save_confirmation.get_label().autowrap_mode
		== TextServer.AUTOWRAP_WORD_SMART
	)
	game.links_options_button.pressed.emit()
	assert(game.options_page_title.text == "LINKS")
	assert(game.links_options.visible)
	assert(not game.gameplay_options.visible)
	assert(not game.sound_options.visible)
	assert(not game.graphics_options.visible)
	assert(not game.save_options.visible)
	assert(game.links_options_button.texture_normal != null)
	assert(game.itch_link_button.text == "ITCH.IO")
	assert(game.kofi_link_button.text == "KO-FI")
	assert(game.itch_link_button.flat)
	assert(game.kofi_link_button.flat)
	assert(
		game.itch_link_button.get_theme_color("font_focus_color")
		== game.OPTIONS_SELECTED_COLOR
	)
	assert(
		game.kofi_link_button.get_theme_color("font_hover_color")
		== game.OPTIONS_SELECTED_COLOR
	)
	assert(game.ITCH_URL == "https://juel-s.itch.io/")
	assert(game.KOFI_URL == "https://ko-fi.com/juels")
	assert(not game.itch_link_button.pressed.get_connections().is_empty())
	assert(not game.kofi_link_button.pressed.get_connections().is_empty())
	game.options_back_button.pressed.emit()
	assert(not game.options_menu.visible)
	game.progression_button.pressed.emit()
	assert(game.progression_menu.visible)
	var snapshot := game._progression_snapshot()
	assert((snapshot.achievements as Array).size() == AchievementRegistry.create_all().size())
	assert((snapshot.bonuses as Array).size() == BonusRegistry.create_all().size())
	assert(
		(snapshot.special_rules as Array).size()
		== SpecialRuleRegistry.create_all_rules().size()
	)
	assert((snapshot.fonts as Array).size() == FontRegistry.create_all().size())
	assert(
		(snapshot.palettes as Array).size()
		== ColorPaletteRegistry.create_all().size()
	)
	var palette_achievement_ids: Array[StringName] = []
	for palette in game.palette_manager.definitions:
		assert(palette.colors.size() == 10)
		if palette.required_achievement == null:
			continue
		assert(not palette_achievement_ids.has(palette.required_achievement.id))
		palette_achievement_ids.append(palette.required_achievement.id)
	game._on_progression_palette_selected(&"arcade_crt")
	assert(game.palette_manager.selected_palette == &"arcade_crt")
	assert(game.hand_manager.tile_colors.size() == 10)
	assert(
		game.hand_manager.tile_colors[0]
		== ColorPaletteRegistry.create_all()[1].colors[0]
	)
	var falling_blocks := ColorPaletteRegistry.create_all()[2]
	assert(falling_blocks.id == &"falling_blocks")
	assert(falling_blocks.colors[0] == Color("#5D6472"))
	assert(falling_blocks.colors[9] == Color("#7CB342"))
	assert(falling_blocks.required_achievement.id == &"max_piles")
	assert(not game.palette_manager.unlocked.has(&"falling_blocks"))
	game.palette_manager.unlock_for_achievement(&"max_piles")
	assert(game.palette_manager.unlocked.has(&"falling_blocks"))
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	assert(game._handle_global_shortcut(escape))
	assert(not game.progression_menu.visible)
	game.queue_free()
	print("Progression game integration tests passed.")
	quit()

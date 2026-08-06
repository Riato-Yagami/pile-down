extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	await process_frame
	assert(game.options_button.texture_normal != null)
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
	assert(game.options_page_title.text == "SOUND")
	assert(game.sound_options.visible)
	assert(game.sound_options is VBoxContainer)
	assert(not game.graphics_options.visible)
	assert(not game.save_options.visible)
	game.graphics_options_button.pressed.emit()
	assert(game.options_page_title.text == "GRAPHICS")
	assert(game.graphics_options.visible)
	assert(not game.sound_options.visible)
	assert(not game.save_options.visible)
	assert(game.graphics_options is VBoxContainer)
	assert(game.adaptive_resolution_button.flat)
	assert(game.locked_resolution_button.flat)
	assert(game.adaptive_resolution_button is HighlightButton)
	assert(game.locked_resolution_button is HighlightButton)
	assert(game.debug_unlock_all_section.visible == game.Debug.is_enabled())
	assert(game.debug_unlock_all_button is HighlightButton)
	assert(game.debug_unlock_all_button.icon == game.UNCHECKED_TEXTURE)
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
	assert(not game.sound_options.visible)
	assert(game.save_options.visible)
	assert(game.save_options is VBoxContainer)
	assert(game.export_save_button.flat)
	assert(game.import_save_button.flat)
	assert(game.delete_save_button.flat)
	assert(game.export_save_button is HighlightButton)
	assert(game.export_save_dialog.use_native_dialog)
	assert(
		game.delete_save_confirmation.get_label().autowrap_mode
		== TextServer.AUTOWRAP_WORD_SMART
	)
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
	for palette_value in snapshot.palettes as Array:
		assert((palette_value as Dictionary).colors.size() == 10)
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
	game.Debug.toggle_unlock_everything()
	game._apply_debug_unlock_everything()
	game._refresh_debug_unlock_button()
	assert(game.debug_unlock_all_button.icon == game.SELECTED_TEXTURE)
	assert(
		game.achievement_manager.unlocked.size()
		== game.achievement_manager.definitions.size()
	)
	assert(game.font_manager.unlocked.size() == game.font_manager.definitions.size())
	assert(
		game.palette_manager.unlocked.size()
		== game.palette_manager.definitions.size()
	)
	game.Debug.toggle_unlock_everything()
	game._refresh_debug_unlock_button()
	assert(game.debug_unlock_all_button.icon == game.UNCHECKED_TEXTURE)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	assert(game._handle_global_shortcut(escape))
	assert(not game.progression_menu.visible)
	game.queue_free()
	print("Progression game integration tests passed.")
	quit()

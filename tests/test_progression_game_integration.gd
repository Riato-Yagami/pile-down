extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	var artwork := game.get_node("Artwork")
	assert(game.dust_pool.get_parent() == artwork)
	assert(game.dust_pool.get_index() > artwork.get_node("DeformationOverlay").get_index())
	var stripe_material := artwork.get_node("BackgroundArt").material as ShaderMaterial
	assert(is_equal_approx(
		float(stripe_material.get_shader_parameter("stripe_scroll_speed")),
		float(preload(
			"res://resources/materials/StripeBackgroundMaterial.tres"
		).get_shader_parameter("stripe_scroll_speed"))
	))
	await process_frame
	assert(game.hand_tray is NinePatchRect)
	assert(game.start_adaptive_in_editor)
	assert(game.hand_tray.patch_margin_left == 18)
	assert(game.hand_tray.patch_margin_right == 18)
	assert(not game.progression_menu.visible)
	assert(not game.progression_menu.show_editor_preview)
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
	game._pause_achievement_notifications(&"test_announcement")
	game.achievement_manager.achievement_unlocked.emit(
		AchievementRegistry.create_all()[7]
	)
	await process_frame
	assert(not game.achievement_popup.visible)
	assert(game._achievement_notification_queue.size() == 1)
	game.achievement_popup_after_announcements_delay = 0.05
	game._resume_achievement_notifications(&"test_announcement")
	await process_frame
	assert(not game.achievement_popup.visible)
	await create_timer(0.06).timeout
	assert(game.achievement_popup.visible)
	assert(game.achievement_popup_title.text.contains("NO SHORTCUTS"))
	var achievement_content := game.achievement_popup_title.get_parent() as HBoxContainer
	var achievement_icon := achievement_content.get_node("Icon") as TextureRect
	assert(achievement_content.get_theme_constant("separation") == 2)
	assert(achievement_icon.get_index() + 1 == game.achievement_popup_title.get_index())
	assert(is_equal_approx(
		game.achievement_popup.position.x,
		floorf(
			(game.get_viewport_rect().size.x - game.achievement_popup.size.x) * 0.5
		)
	))
	game._pause_achievement_notifications(&"announcement_during_popup")
	assert(game.achievement_popup.visible)
	game._resume_achievement_notifications(&"announcement_during_popup")
	assert(
		game.achievement_popup.get_global_rect().position.y
		>= game.timer_ring.get_global_rect().end.y + 8.0
	)
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
	assert(game.dust_effects_button.flat)
	assert(game.dust_effects_button.text.strip_edges() == "BACKGROUND DEFORMATION")
	assert(game.background_enabled_button.flat)
	assert(game.background_enabled_button.text == "SHOW BACKGROUND")
	assert(
		game.dust_effects_button.get_parent().get_node("BackgroundLabel").text
		== "BACKGROUND"
	)
	assert(
		game.dust_effects_button.autowrap_mode
		== TextServer.AUTOWRAP_WORD_SMART
	)
	assert(
		game.dust_effects_button.get_global_rect().end.x
		<= game.options_menu.get_global_rect().end.x
	)
	assert(game.dust_effects_button.icon == game.SELECTED_TEXTURE)
	assert(game.dust_pool.enabled)
	assert(game.background_enabled_button.icon == game.SELECTED_TEXTURE)
	assert(game.dust_effects_button.visible)
	assert(game.deformable_stripe_background.visible)
	assert(game.get_node_or_null("%LightingEffectsButton") == null)
	assert(not game.relief_lighting.enabled)
	assert(not game.uniform_relief_light.visible)
	assert(not game.pointer_relief_light.visible)
	assert(game.uniform_relief_light.range_item_cull_mask == 3)
	assert(game.pointer_relief_light.range_item_cull_mask == 2)
	assert(game.graphics_options_button.texture_normal is CanvasTexture)
	assert(
		(game.graphics_options_button.texture_normal as CanvasTexture).normal_texture
		!= null
	)
	var normal_energy := game.uniform_relief_light.energy
	var relief_key := InputEventKey.new()
	relief_key.keycode = KEY_V
	relief_key.pressed = true
	assert(game._handle_debug_shortcut(relief_key) == game.Debug.is_enabled())
	if game.Debug.is_enabled():
		assert(game.uniform_relief_light.energy > normal_energy)
		assert(not game.uniform_relief_light.visible)
		assert(not game.pointer_relief_light.visible)
	game.dust_effects_button.pressed.emit()
	assert(game.dust_effects_button.icon == game.UNCHECKED_TEXTURE)
	assert(not game.dust_pool.enabled)
	assert(game.deformable_stripe_background.visible)
	assert(is_zero_approx(float(
		game.deformable_stripe_background._shader_material.get_shader_parameter(
			"effect_enabled"
		)
	)))
	assert(float(
		game.deformable_stripe_background._stripe_material.get_shader_parameter(
			"effect_enabled"
		)
	) > 0.0)
	var round_wave := game.get_node("Gameplay/RoundWave") as Control
	game._show_round_wave()
	assert(round_wave.visible)
	await create_timer(0.65).timeout
	assert(not round_wave.visible)
	game.dust_effects_button.pressed.emit()
	assert(game.dust_effects_button.icon == game.SELECTED_TEXTURE)
	assert(game.dust_pool.enabled)
	game._show_round_wave()
	assert(not round_wave.visible)
	game.background_enabled_button.pressed.emit()
	assert(game.background_enabled_button.icon == game.UNCHECKED_TEXTURE)
	assert(not game.deformable_stripe_background.visible)
	assert(not game.dust_effects_button.visible)
	assert(not game._is_background_deformation_active())
	game.background_enabled_button.pressed.emit()
	assert(game.background_enabled_button.icon == game.SELECTED_TEXTURE)
	assert(game.deformable_stripe_background.visible)
	assert(game.dust_effects_button.visible)
	assert(game.adaptive_resolution_button is HighlightButton)
	assert(game.adaptive_resolution_button.text == "ADAPTIVE SCREEN SIZE")
	assert(game.adaptive_resolution_button.get_theme_stylebox("focus") is StyleBoxEmpty)
	assert(
		game.adaptive_resolution_button.get_theme_color("font_color")
		== game.OPTION_TEXT_COLOR
	)
	game._set_adaptive_resolution(false)
	assert(game.get_window().content_scale_size == Vector2i(256, 320))
	assert(game.adaptive_resolution_button.icon == game.UNCHECKED_TEXTURE)
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
	game.adaptive_resolution_button.pressed.emit()
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
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	assert(game._handle_global_shortcut(escape))
	assert(not game.progression_menu.visible)
	game.queue_free()
	print("Progression game integration tests passed.")
	quit()

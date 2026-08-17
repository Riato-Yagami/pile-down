class_name GameOptionsController
extends RefCounted


static func setup_audio(game: GameManager) -> void:
	var config := _load_config(game)
	game.music_volume_slider.set_value_no_signal(
		float(config.get_value("audio", "music_volume", 1.0)) * 100.0
	)
	game.sound_volume_slider.set_value_no_signal(
		float(config.get_value("audio", "sound_volume", 1.0)) * 100.0
	)
	if game.music_volume_slider.value > 0.0:
		game._music_volume_before_mute = game.music_volume_slider.value
	if game.sound_volume_slider.value > 0.0:
		game._sound_volume_before_mute = game.sound_volume_slider.value
	game.music_volume_slider.value_changed.connect(
		game._on_volume_changed.bind(game.MUSIC_BUS_NAME, "music_volume")
	)
	game.sound_volume_slider.value_changed.connect(
		game._on_volume_changed.bind(game.SFX_BUS_NAME, "sound_volume")
	)
	apply_bus_volume(game.MUSIC_BUS_NAME, game.music_volume_slider.value / 100.0)
	apply_bus_volume(game.SFX_BUS_NAME, game.sound_volume_slider.value / 100.0)


static func style_buttons(game: GameManager) -> void:
	var buttons: Array[Button] = [
		game.achievement_notifications_button,
		game.timer_display_button,
		game.adaptive_resolution_button,
		game.dust_effects_button,
		game.background_enabled_button,
		game.export_save_button,
		game.import_save_button,
		game.delete_save_button,
		game.itch_link_button,
		game.kofi_link_button,
	]
	for button in buttons:
		button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
		for color_name in [&"font_color", &"font_disabled_color"]:
			button.add_theme_color_override(color_name, game.OPTION_TEXT_COLOR)
		for color_name in [
			&"font_hover_color", &"font_pressed_color",
			&"font_hover_pressed_color", &"font_focus_color",
		]:
			button.add_theme_color_override(color_name, game.OPTIONS_SELECTED_COLOR)


static func setup_gameplay(game: GameManager) -> void:
	var config := _load_config(game)
	game._achievement_notifications_enabled = bool(config.get_value(
		"gameplay", "achievement_notifications", true
	))
	game._global_timer_enabled = bool(config.get_value(
		"gameplay", "show_timer", true
	))
	refresh_gameplay(game)


static func toggle_achievement_notifications(game: GameManager) -> void:
	game._achievement_notifications_enabled = not game._achievement_notifications_enabled
	if not game._achievement_notifications_enabled:
		game._achievement_notification_queue.clear()
		game.achievement_popup.visible = false
	save_gameplay(game, "achievement_notifications", game._achievement_notifications_enabled)
	refresh_gameplay(game)


static func toggle_timer(game: GameManager) -> void:
	game._global_timer_enabled = not game._global_timer_enabled
	save_gameplay(game, "show_timer", game._global_timer_enabled)
	refresh_gameplay(game)


static func save_gameplay(game: GameManager, key: String, value: bool) -> void:
	var config := _load_config(game)
	config.set_value("gameplay", key, value)
	config.save(game.AUDIO_CONFIG_PATH)


static func refresh_gameplay(game: GameManager) -> void:
	game.achievement_notifications_button.icon = (
		game.SELECTED_TEXTURE
		if game._achievement_notifications_enabled else game.UNCHECKED_TEXTURE
	)
	game.timer_display_button.icon = (
		game.SELECTED_TEXTURE
		if game._global_timer_enabled else game.UNCHECKED_TEXTURE
	)
	game.run_time_label.visible = game._global_timer_enabled and not game.splash.visible


static func setup_graphics(game: GameManager) -> void:
	var config := _load_config(game)
	game._adaptive_resolution = bool(config.get_value(
		"graphics", "adaptive_resolution", false
	))
	game._dust_enabled = bool(config.get_value("graphics", "dust_effects", true))
	game._background_enabled = bool(config.get_value(
		"graphics", "background_enabled", true
	))
	if OS.has_feature("editor") and game.start_adaptive_in_editor:
		game._adaptive_resolution = true
	apply_resolution(game)
	refresh_dust(game)
	refresh_background(game)
	game.relief_lighting.set_enabled(false)


static func setup_dust_pool(game: GameManager) -> void:
	game.deformable_stripe_background = (
		game.get_node("Artwork") as DeformableStripeBackground
	)
	game.deformable_stripe_background.setup()
	game.deformable_stripe_background.enabled = game._dust_enabled
	game.deformable_stripe_background.visible = game._background_enabled
	var pool_control := Control.new()
	pool_control.set_script(game.DustPoolScript)
	game.dust_pool = pool_control as DustPool
	game.dust_pool.name = "DustPool"
	game.get_node("Artwork").add_child(game.dust_pool)
	game.dust_pool.setup(
		dust_particle_target_count(game),
		DebugSettings.is_dust_debug_visible(),
		game.dust_viscosity,
		game.dust_particle_color
	)
	game.dust_pool.particles_visible = false
	game.dust_pool.enabled = game._dust_enabled


static func resize_dust_distribution(game: GameManager) -> void:
	if is_instance_valid(game.relief_lighting):
		var viewport_size := game.get_viewport_rect().size
		game.relief_lighting.follow_pointer(viewport_size * 0.5, viewport_size)
	if is_instance_valid(game.deformable_stripe_background):
		game.deformable_stripe_background.call_deferred("resize_to_viewport")
	if is_instance_valid(game.dust_pool):
		game.dust_pool.call_deferred(
			"resize_to_viewport", dust_particle_target_count(game)
		)


static func dust_particle_target_count(game: GameManager) -> int:
	var viewport_size := game.get_viewport_rect().size
	return maxi(roundi(
		game.dust_particles_per_10000_pixels
		* viewport_size.x * viewport_size.y / 10000.0
	), 0)


static func rebuild_dust_pool(game: GameManager) -> void:
	if not is_instance_valid(game.dust_pool):
		return
	game.dust_pool.setup(
		dust_particle_target_count(game),
		DebugSettings.is_dust_debug_visible(),
		game.dust_viscosity,
		game.dust_particle_color
	)
	game.dust_pool.enabled = game._dust_enabled


static func toggle_dust(game: GameManager) -> void:
	game._dust_enabled = not game._dust_enabled
	var config := _load_config(game)
	config.set_value("graphics", "dust_effects", game._dust_enabled)
	config.save(game.AUDIO_CONFIG_PATH)
	if is_instance_valid(game.dust_pool):
		game.dust_pool.enabled = game._dust_enabled
	if is_instance_valid(game.deformable_stripe_background):
		game.deformable_stripe_background.enabled = game._dust_enabled
	refresh_dust(game)


static func refresh_dust(game: GameManager) -> void:
	game.dust_effects_button.modulate = Color.WHITE
	game.dust_effects_button.icon = (
		game.SELECTED_TEXTURE if game._dust_enabled else game.UNCHECKED_TEXTURE
	)


static func toggle_background(game: GameManager) -> void:
	game._background_enabled = not game._background_enabled
	var config := _load_config(game)
	config.set_value("graphics", "background_enabled", game._background_enabled)
	config.save(game.AUDIO_CONFIG_PATH)
	if is_instance_valid(game.deformable_stripe_background):
		game.deformable_stripe_background.visible = game._background_enabled
	refresh_background(game)


static func refresh_background(game: GameManager) -> void:
	game.background_enabled_button.modulate = Color.WHITE
	game.background_enabled_button.icon = (
		game.SELECTED_TEXTURE
		if game._background_enabled else game.UNCHECKED_TEXTURE
	)
	game.dust_effects_button.visible = game._background_enabled


static func set_adaptive_resolution(game: GameManager, adaptive: bool) -> void:
	game._adaptive_resolution = adaptive
	var config := _load_config(game)
	config.set_value("graphics", "adaptive_resolution", adaptive)
	config.save(game.AUDIO_CONFIG_PATH)
	apply_resolution(game)


static func apply_resolution(game: GameManager) -> void:
	var window := game.get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = game.LOCKED_VIEWPORT_SIZE
	window.content_scale_aspect = (
		Window.CONTENT_SCALE_ASPECT_EXPAND
		if game._adaptive_resolution else Window.CONTENT_SCALE_ASPECT_KEEP
	)
	game.adaptive_resolution_button.modulate = Color.WHITE
	game.adaptive_resolution_button.icon = (
		game.SELECTED_TEXTURE if game._adaptive_resolution else game.UNCHECKED_TEXTURE
	)


static func setup_save_dialogs(game: GameManager) -> void:
	game.export_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	game.import_save_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	for dialog in [game.export_save_dialog, game.import_save_dialog]:
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.json ; JSON save files"])
		dialog.use_native_dialog = true
	game.export_save_dialog.current_file = "pile-down-save.json"
	var confirmation_label := game.delete_save_confirmation.get_label()
	confirmation_label.custom_minimum_size.x = 180.0
	confirmation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func export_save(game: GameManager, path: String) -> void:
	var error := game.save_data_manager.export_json(path)
	game.save_status.text = "SAVE EXPORTED" if error == OK else "EXPORT FAILED"


static func import_save(game: GameManager, path: String) -> void:
	var error := game.save_data_manager.import_json(path)
	if error != OK:
		game.save_status.text = "INVALID SAVE FILE"
		return
	game.get_tree().reload_current_scene()


static func delete_save(game: GameManager) -> void:
	var error := game.save_data_manager.delete_save()
	if error != OK:
		game.save_status.text = "DELETE FAILED"
		return
	game.get_tree().reload_current_scene()


static func volume_changed(
	game: GameManager, value: float, bus_name: StringName, config_key: String
) -> void:
	var linear_volume := value / 100.0
	apply_bus_volume(bus_name, linear_volume)
	var config := _load_config(game)
	config.set_value("audio", config_key, linear_volume)
	config.save(game.AUDIO_CONFIG_PATH)


static func apply_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(
		bus_index, linear_to_db(maxf(linear_volume, 0.0001))
	)
	AudioServer.set_bus_mute(bus_index, is_zero_approx(linear_volume))


static func _load_config(game: GameManager) -> ConfigFile:
	var config := ConfigFile.new()
	config.load(game.AUDIO_CONFIG_PATH)
	return config

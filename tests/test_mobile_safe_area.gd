extends SceneTree

class SimulatedMobile:
	extends "res://resources/scripts/settings/display/MobileDisplay.gd"
	var reported_safe := Rect2()
	func is_mobile() -> bool:
		return true
	func supports_system_bars() -> bool:
		return true
	func _apply_system_bars() -> void:
		pass
	func _read_window_size() -> Vector2:
		return Vector2(get_window().size)
	func _read_safe_area() -> Rect2:
		return reported_safe


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(40.0).timeout.connect(func(): quit(1))
	var mobile := root.get_node("MobileDisplay")
	assert(not mobile.is_mobile(), "Desktop must not use mobile layout")
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	assert(not main.get_node("GameCenter/Game").system_bars_button.visible)
	main.queue_free()
	await process_frame
	mobile.set_script(SimulatedMobile)
	mobile._ready()
	var config := SaveConfig.load_current()
	if config.has_section_key("graphics", "show_system_bars"):
		config.erase_section_key("graphics", "show_system_bars")
	if config.has_section_key("graphics", "ignore_notch"):
		config.erase_section_key("graphics", "ignore_notch")
	config.save(SaveConfig.PATH)
	mobile.reload_settings()
	assert(mobile.show_system_bars, "System bars must default to visible")
	main = preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	var game := main.get_node("GameCenter/Game") as GameManager
	assert(game.system_bars_button.visible)
	assert(not game.ignore_notch_button.visible)
	mobile.set_ignore_notch(true)
	assert(not mobile.ignore_notch, "The notch option is unavailable while bars are visible")
	game.system_bars_button.pressed.emit()
	assert(not mobile.show_system_bars)
	assert(game.ignore_notch_button.visible and not game.ignore_notch_button.disabled)
	mobile.reload_settings()
	assert(not mobile.show_system_bars, "Immersive preference must persist")
	game.system_bars_button.pressed.emit()
	assert(mobile.show_system_bars)
	for dimensions in [Vector2i(1080, 2424), Vector2i(2424, 1080), Vector2i(1600, 2560)]:
		root.size = dimensions
		for insets in [Vector4(0, 150, 0, 90), Vector4(110, 0, 70, 60), Vector4(0, 80, 0, 0)]:
			mobile.reported_safe = Rect2(
				Vector2(insets.x, insets.y),
				Vector2(dimensions) - Vector2(insets.x + insets.z, insets.y + insets.w)
			)
			mobile._refresh_safe_area()
			for pixel_art in [false, true]:
				game._true_pixel_art_enabled = pixel_art
				for mode in [&"classic", &"semi_adaptive", &"adaptive", &"menu_adaptive"]:
					game._screen_size_mode = mode
					game.GameOptionsControllerScript.apply_resolution(game)
					await _settle()
					for control: Control in [game.splash, game.gameplay_layer, game.quit_popup, game.bonus_selection, game.overlay]:
						var physical := root.get_screen_transform() * control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)
						assert(mobile.reported_safe.grow(1.0).encloses(physical), "%s escapes safe area in %s: %s vs %s" % [control.name, mode, physical, mobile.reported_safe])
					assert(game.gameplay_layer.size.x >= 256 and game.gameplay_layer.size.y >= 320)
					var background := game.splash.get_node("Background") as Control
					var backdrop := background.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, background.size)
					assert(backdrop.grow(0.01).encloses(root.get_visible_rect()), "The menu backdrop must cover the whole viewport")
					for overlay: Control in [game.bonus_selection, game.get_node("PresentationLayers/SpecialRuleAnnouncementLayer/SpecialRuleAnnouncement")]:
						var scrim := overlay.get_node("Scrim") as Control
						var scrim_rect := scrim.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, scrim.size)
						assert(scrim_rect.grow(0.01).encloses(root.get_visible_rect()), "%s backdrop must cover system bar insets in %s" % [overlay.name, mode])
	game.system_bars_button.pressed.emit()
	game.ignore_notch_button.pressed.emit()
	await _settle()
	assert(mobile.ignore_notch)
	assert(mobile.safe_rect(root).is_equal_approx(root.get_visible_rect()))
	mobile.reload_settings()
	assert(mobile.ignore_notch, "The notch preference must persist")
	game.system_bars_button.pressed.emit()
	await _settle()
	assert(not game.ignore_notch_button.visible and game.ignore_notch_button.disabled)
	assert(not mobile.safe_rect(root).is_equal_approx(root.get_visible_rect()), "Visible bars always restore the safe area")
	# The backdrop must also extend across the insets during the return swipe.
	game.splash.reparent(game.menu_transition_layer, true)
	await game._play_return_to_menu_transition()
	var returning_background := game.splash.get_node("Background") as Control
	var returning_rect := returning_background.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, returning_background.size)
	assert(returning_rect.grow(0.01).encloses(root.get_visible_rect()))
	game.splash.reparent(game.screens, true)
	game._restore_splash_screen_layout()
	main.queue_free()
	await process_frame
	print("Mobile safe area: portrait, landscape, tablet, all display modes and saved system bars passed.")
	quit()


func _settle() -> void:
	for frame in 10:
		await process_frame

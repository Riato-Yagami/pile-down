class_name GameMenuPresenter
extends RefCounted

## Menu navigation, cosmetic application and progression summaries.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func open_progression_menu(host: GameManager) -> void:
	host.progression_menu.open(host._progression_snapshot())
	host._submenu_swipe_controller.open(host.progression_menu, host._submenu_travel_distance())


static func submenu_travel_distance(host: GameManager) -> float:
	if is_instance_valid(host.screens) and host.screens.size.x > 0.0:
		return host.screens.size.x
	return host.get_viewport_rect().size.x


static func open_options_menu(host: GameManager) -> void:
	host.options_menu.visible = true
	host._show_options_page(host._options_page)
	host._submenu_swipe_controller.open(host.options_menu, host._submenu_travel_distance())
	match host._options_page:
		host.OPTION_GAMEPLAY:
			host.achievement_notifications_button.grab_focus()
		host.OPTION_SOUND:
			host.music_volume_slider.grab_focus()
		host.OPTION_GRAPHICS:
			var screen_size_selector := (
				host.adaptive_resolution_button.get_parent().get_node_or_null(
					"ScreenSizeModeSelector"
				) as Control
			)
			if screen_size_selector != null:
				screen_size_selector.grab_focus()
			else:
				host.adaptive_resolution_button.grab_focus()
		host.OPTION_SAVE:
			host.save_options_button.grab_focus()
		host.OPTION_LINKS:
			host.link_button_template.grab_focus()


static func show_options_page(host: GameManager, page: int, animate := false) -> void:
	var previous_page := host._options_page
	host._options_page = clampi(page, host.OPTION_GAMEPLAY, host.OPTION_LINKS)
	host.gameplay_options.visible = host._options_page == host.OPTION_GAMEPLAY
	host.sound_options.visible = host._options_page == host.OPTION_SOUND
	host.graphics_options.visible = host._options_page == host.OPTION_GRAPHICS
	host.save_options.visible = host._options_page == host.OPTION_SAVE
	host.links_options.visible = host._options_page == host.OPTION_LINKS
	match host._options_page:
		host.OPTION_GAMEPLAY:
			host.options_page_title.text = "GAMEPLAY"
		host.OPTION_SOUND:
			host.options_page_title.text = "SOUND"
		host.OPTION_GRAPHICS:
			host.options_page_title.text = "GRAPHICS"
		host.OPTION_SAVE:
			host.options_page_title.text = "SAVE DATA"
		host.OPTION_LINKS:
			host.options_page_title.text = "LINKS"
	host.gameplay_options_button.modulate = (
		host.OPTIONS_SELECTED_COLOR if host._options_page == host.OPTION_GAMEPLAY else Color.WHITE
	)
	host.sound_options_button.modulate = (
		host.OPTIONS_SELECTED_COLOR if host._options_page == host.OPTION_SOUND else Color.WHITE
	)
	host.graphics_options_button.modulate = (
		host.OPTIONS_SELECTED_COLOR if host._options_page == host.OPTION_GRAPHICS else Color.WHITE
	)
	host.save_options_button.modulate = (
		host.OPTIONS_SELECTED_COLOR if host._options_page == host.OPTION_SAVE else Color.WHITE
	)
	host.links_options_button.modulate = (
		host.OPTIONS_SELECTED_COLOR if host._options_page == host.OPTION_LINKS else Color.WHITE
	)
	host.GameOptionsControllerScript.refresh_screen_size_options(host)
	if animate and previous_page != host._options_page:
		host._submenu_page_animator.play(
			host.options_page_title.get_parent() as Control,
			signi(host._options_page - previous_page)
		)


static func setup_links(host: GameManager) -> void:
	var catalog := preload("res://resources/data/links.tres") as DataCatalog
	var template := host.link_button_template
	var buttons: Array[Button] = []
	for index in catalog.enabled_data.size():
		var button := template if index == 0 else template.duplicate(Node.DUPLICATE_SCRIPTS) as Button
		if index > 0:
			button.name = "Link%d" % index
			button.unique_name_in_owner = false
			host.links_options.add_child(button)
		buttons.append(button)
	for index in buttons.size():
		var link := catalog.enabled_data[index] as LinkData
		buttons[index].text = link.title
		buttons[index].pressed.connect(host._open_external_link.bind(link.url))
	template.visible = not buttons.is_empty()


static func open_external_link(host: GameManager, url: String) -> void:
	if not url.begins_with("https://"):
		push_warning("Refusing to open a non-HTTPS external link.")
		return
	OS.shell_open(url)


static func close_options_menu(host: GameManager) -> void:
	if not host.options_menu.visible:
		return
	await host._submenu_swipe_controller.close(host.options_menu, host._submenu_travel_distance())
	host.options_button.grab_focus()


static func on_progression_menu_closed(host: GameManager) -> void:
	await host._submenu_swipe_controller.close(
		host.progression_menu, host._submenu_travel_distance()
	)
	host.progression_button.grab_focus()


static func on_progression_font_selected(host: GameManager, font_id: StringName) -> void:
	if host.font_manager.select(font_id):
		host._apply_tile_font()
		host.progression_menu.refresh(host._progression_snapshot())


static func on_progression_palette_selected(host: GameManager, palette_id: StringName) -> void:
	if host.palette_manager.select(palette_id):
		host._apply_tile_palette()
		host.progression_menu.refresh(host._progression_snapshot())


static func apply_tile_font(host: GameManager) -> void:
	var data := host.font_manager.find(host.font_manager.selected_font)
	if data == null:
		return
	host.hand_manager.value_font = data.font
	host.hand_manager.value_font_size = data.tile_font_size
	host.hand_manager.value_font_offset = data.tile_font_offset
	host.hand_manager.override_hidden_tile_with_font = data.override_hidden_tile_with_font
	for card in host.hand_manager.current_cards:
		if is_instance_valid(card):
			card.set_value_font(
				data.font,
				data.tile_font_size,
				data.tile_font_offset,
				data.override_hidden_tile_with_font
			)
	for pile in host.piles:
		if is_instance_valid(pile):
			pile.set_value_font(
				data.font,
				data.tile_font_size,
				data.tile_font_offset,
				data.override_hidden_tile_with_font
			)


static func apply_tile_palette(host: GameManager) -> void:
	var data := host.palette_manager.find(host.palette_manager.selected_palette)
	if data == null:
		return
	var colors := data.normalized_colors()
	host.hand_manager.tile_colors = colors
	for card in host.hand_manager.current_cards:
		if is_instance_valid(card):
			card.set_tile_palette(colors)
	for pile in host.piles:
		if is_instance_valid(pile):
			pile.set_tile_palette(colors)
	host.theme_manager.set_active_theme(host._debug_or_selected_palette())


static func debug_or_selected_palette(host: GameManager) -> StringName:
	if host.Debug.is_enabled() and not host.Debug.FORCE_THEME_PALETTE.strip_edges().is_empty():
		var forced := StringName(host.Debug.FORCE_THEME_PALETTE.strip_edges())
		if host.palette_manager.find(forced) != null:
			return forced
	return host.palette_manager.selected_palette


static func on_theme_changed(host: GameManager, theme: ThemePaletteData) -> void:
	host._apply_global_theme()


static func apply_global_theme(host: GameManager) -> void:
	var theme := host.theme_manager.get_active_theme()
	if is_instance_valid(host.background_effects):
		host.background_effects.apply_theme(theme)
	if is_instance_valid(host.background_manager):
		host.background_manager.apply_theme(theme)
	host._sync_shader_background_visibility()
	host.theme_manager.apply_theme_to_control(host.options_menu)
	host.theme_manager.apply_theme_to_control(host.progression_menu)
	if is_instance_valid(host.overlay_scrim):
		host.overlay_scrim.color = Color(0.969, 0.965, 0.949, 0.92)
	if is_instance_valid(host.replay_transition_mask):
		host.replay_transition_mask.color = Color(0.969, 0.965, 0.949, 1.0)


static func sync_shader_background_visibility(host: GameManager) -> void:
	var show_shader_background := host._background_enabled and (
		not host.splash.visible or host._screen_size_mode != &"classic"
	)
	if is_instance_valid(host.background_effects):
		host.background_effects.set_base_pattern_enabled(show_shader_background)
	if is_instance_valid(host.background_manager):
		host.background_manager.set_enabled(show_shader_background)
	var splash_background := host.splash.get_node_or_null("Background") as ColorRect
	if splash_background != null:
		splash_background.visible = host.splash.visible
		if splash_background.visible:
			host._fit_splash_background_to_canvas()


static func append_new_checkpoint_summary(host: GameManager) -> void:
	host._append_new_progression_summary()


static func append_new_progression_summary(host: GameManager) -> void:
	var lines := PackedStringArray()
	var checkpoint_line := host._new_checkpoint_summary_line()
	if not checkpoint_line.is_empty():
		lines.append(host._progression_icon_line(
			host.PROGRESSION_CHECKPOINT_ICON, PackedStringArray([checkpoint_line])
		))
	var bonus_titles := host._new_bonus_titles()
	if not bonus_titles.is_empty():
		lines.append(host._progression_icon_line(host.PROGRESSION_BONUS_ICON, bonus_titles))
	var rule_titles := host._new_rule_titles()
	if not rule_titles.is_empty():
		lines.append(host._progression_icon_line(host.PROGRESSION_RULE_ICON, rule_titles))
	var achievement_titles := host._new_achievement_titles()
	if not achievement_titles.is_empty():
		lines.append(
			host._progression_icon_line(
				host.PROGRESSION_ACHIEVEMENT_ICON, achievement_titles
			)
		)
	if lines.is_empty():
		host.overlay_unlocks.visible = false
		host.overlay_unlocks.text = ""
		return
	host.overlay_unlocks.text = "[center]%s[/center]" % "\n".join(lines)
	host.overlay_unlocks.visible = true


static func progression_icon_line(
	host: GameManager, icon_path: String, titles: PackedStringArray
) -> String:
	return "+ [img=16x16]%s[/img] %s" % [
		icon_path, " + ".join(titles),
	]


static func new_checkpoint_summary_line(host: GameManager) -> String:
	if host.newly_unlocked_checkpoints.is_empty():
		return ""
	var checkpoint_ids: Array[int] = []
	for checkpoint_id in host.newly_unlocked_checkpoints:
		if not checkpoint_ids.has(checkpoint_id):
			checkpoint_ids.append(checkpoint_id)
	checkpoint_ids.sort()
	var labels := PackedStringArray()
	for checkpoint_id in checkpoint_ids:
		labels.append(str(checkpoint_id))
	var heading := "CHECKPOINTS" if checkpoint_ids.size() > 1 else "CHECKPOINT"
	return "%s: %s" % [
		heading, " + ".join(labels),
	]


static func new_bonus_titles(host: GameManager) -> PackedStringArray:
	var titles := PackedStringArray()
	for bonus_id in host.newly_discovered_bonuses:
		for data in host.bonus_manager.definitions:
			if data.id == bonus_id and not titles.has(data.title):
				titles.append(data.title)
				break
	return titles


static func new_rule_titles(host: GameManager) -> PackedStringArray:
	var titles := PackedStringArray()
	for rule_id in host.newly_encountered_rules:
		for data in SpecialRuleRegistry.create_all_rules():
			if data.id == rule_id and not titles.has(data.title):
				titles.append(data.title)
				break
	return titles


static func new_achievement_titles(host: GameManager) -> PackedStringArray:
	var titles := PackedStringArray()
	for achievement_id in host.newly_unlocked_achievements:
		var data := host.achievement_manager.find(achievement_id)
		if data != null and not titles.has(data.title):
			titles.append(data.title)
	return titles
